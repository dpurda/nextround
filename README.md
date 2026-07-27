# NextRound

A Ruby on Rails application for preparing for conducting, and reviewing mock
technical interviews.

## Solution overview

NextRound supports three roles on a single `User` model:

- **Admin** — invites interviewers and candidates, sees everything unscoped,
  global reporting.
- **Interviewer** — invites candidates, schedules and conducts interviews,
  records feedback, sees only their own interviews/candidates.
- **Candidate** — reviews their own interview history and feedback
  (read-only), maintains a CV-style profile.

There is no public sign-up. Every account is created by an invite from
someone with permission to create that role (admin → interviewer/candidate,
interviewer → candidate only), and claimed with a one-time 16-digit code
instead of an emailed link — see [Design decisions](#design-decisions) for
why.

**Core features**
- Interview session management: create, view, edit, and mark interviews as
  completed, with status transitions enforced (can't complete without
  feedback recorded first)
- Candidate tracking: candidate = a `User` with a `CandidateProfile`,
  including a full CV (work experience and education as repeatable,
  add/remove-in-the-browser sections, not flat text fields)
- Feedback: strengths, areas for improvement, a hire/no-hire recommendation,
  and a 1–5 rating per interview, editable inline on the interview page
  without a page reload (Turbo Frames + Turbo Streams)
- Search & discovery: free-text + filtered search (Ransack) and pagination
  (Pagy) on both the interviews list and the invites list
- Reporting: a role-scoped dashboard (totals, completion rate, status and
  recommendation breakdowns, interviews-per-week and average-rating trends)
  using the same interviewer/candidate/admin scoping as everywhere else in
  the app

## Tech stack

| Concern | Choice |
|---|---|
| Backend | Ruby on Rails 8 (monolith) |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS, importmap (no Node build step) |
| Database | SQLite |
| Auth | Devise (customized — no public signup, no email) |
| Authorization | Pundit |
| Search / pagination | Ransack / Pagy |
| Charts | Chartkick + groupdate |
| Rate limiting | rack-attack |
| Testing | RSpec, FactoryBot, Faker |

## Setup instructions

Requires Ruby 3.2+ and no other services (SQLite ships with the app, no
Postgres/Redis/Node to install).

```bash
git clone <this repo>
cd nextround
bundle install

bin/rails db:setup       # creates + migrates + seeds the dev database
bin/rails db:seed        # idempotent — safe to re-run; only the first run
                          # (on an empty DB, outside test env) also generates
                          # ~100 days of realistic Faker demo data
bin/dev                  # starts Rails + the Tailwind watcher
```

Visit `http://localhost:3000` and log in with the seeded admin account:

```
admin@nextround.test / password123
```

(Override via `NEXTROUND_ADMIN_EMAIL`/`NEXTROUND_ADMIN_PASSWORD` env vars.)

From there: **Invites** → invite an interviewer or a candidate → share the
16-digit code shown on screen → open `/claim` (linked from the login page)
to activate that account.

### Running tests

```bash
bundle exec rspec
```

201 examples covering models, policies, and request specs for every
controller action (including authorization boundaries — e.g. an interviewer
can't edit another interviewer's interview, a candidate can't author
feedback).

## Architecture

### Data flow

```
Browser
  │  (Turbo Drive / Turbo Frames / Turbo Streams over standard HTTP)
  ▼
Rails router → Controller (Pundit authorize / policy_scope)
  │
  ▼
ActiveRecord models (validations, enums, business rules)
  │
  ▼
SQLite
```

There is no separate API layer or SPA — Rails renders HTML directly, and
Turbo upgrades specific interactions (the feedback form, the interview edit
form, the status dropdown) to update in place without a full page
navigation. This keeps the whole request/response cycle in one process and
one language, which is the main reason it fits a tight build timeline
without sacrificing interactivity.

### Data model (simplified)

```
User (role: candidate | interviewer | admin)
 ├─ has_one  CandidateProfile ─┬─ has_many WorkExperience
 │                             └─ has_many Education
 ├─ has_one  InterviewerProfile
 ├─ has_many Interview (as interviewer)
 └─ has_many Interview (as candidate)

Interview (interviewer, candidate, status, interview_type)
 └─ has_one Feedback (recommendation, rating, strengths, improvements)
```

### Deployment approach

Not yet deployed (deferred by request during development — this is a
single Docker-deployable Rails app with no external service dependencies,
so it's a `fly launch` / `fly deploy` away using the Dockerfile Rails 8
already generates, with the SQLite file living on a Fly volume).

## Design decisions

Full detail, including the two design-system iterations I actually went
through and *why* — is in [`DESIGN.md`](DESIGN.md). The short version:

- **Rails monolith + Hotwire over a separate API + SPA.** Faster to build
  well within the timeframe while still feeling interactive;
- **Single `User` model with a role enum, not three separate tables.**
  Since "review your own feedback" is a first-class requirement, a
  candidate needs to be a real logged-in identity, not just a data row —
  collapsing candidate/interviewer/admin into one table with a role avoids
  an identity-sync problem between "the person" and "their login."
- **Invite-by-code instead of invite-by-email.** No outbound email
  dependency anywhere in the app (something for the future) the 16-digit
  code is single-use, expires after 7 days, and
  `/claim` is rate-limited (rack-attack) since it's an unauthenticated
  endpoint accepting a code.
- **SQLite instead of Postgres.** This is a practice tool, not a
  multi-writer production system, SQLite removes a whole external service
  (nothing to provision or connect to, locally or in production) at zero
  functional cost at this scale. Rails' database adapter makes moving to
  Postgres later a config change, not a rewrite, so the scaling path is
  kept cheap rather than paid for upfront.
- **Enums over free text** for status/interview type/recommendation —
  indexable, no data drift, simpler reporting queries.
- **Per-role scoping via Pundit `Scope` classes**, reused identically
  everywhere (interview list, dashboard reporting, invites list) rather
  than re-implemented per controller — interviewer sees only their own
  data, admin sees everything, satisfying the security requirement without
  inventing an organizations/teams concept.
- **A hand-rolled nested-attributes pattern for the CV sections**
  (work experience / education) instead of a gem like Cocoon — one small
  reusable Stimulus controller, documented in `DESIGN.md` for reuse on any
  future repeatable form section.

## Assumptions made

- Every interview participant (candidate) needs their own login, since
  reviewing your own feedback is an explicit requirement — there's no
  concept of an "anonymous"/un-invited candidate on an interview.
  Interviewers, similarly, are provisioned accounts, not self-registered.
- One practice group / one admin is the expected scale (no multi-tenant
  organizations) — reasonable for a personal or small-team practice tool.
- "Search previously conducted interviews" and "find participants or
  feedback" are best served by one well-filtered interviews list (title,
  interviewer, candidate, status, type, recommendation, date range) rather
  than three separate search screens.
- A candidate's profile is meant to be filled in like an actual CV
  (multiple work history and education entries), not a single free-text
  "about me" blob.