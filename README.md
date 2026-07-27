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
  (read-only), submits written answers to the interviewer's question
  checklist inline during an interview, maintains a CV-style profile.

There is no public sign-up. Every account is created by an invite from
someone with permission to create that role (admin → interviewer/candidate,
interviewer → candidate only), and claimed with a one-time 16-digit code
instead of an emailed link — see [Design decisions](#design-decisions) for
why.

**Core features**
- Interview session management: create, view, edit, and mark interviews as
  completed, with status transitions enforced (can't complete without
  feedback recorded first). Status also *advances itself* on the common
  path — scheduled → in_progress the moment the candidate submits their
  first answer, and → completed the moment feedback is recorded — so the
  interviewer only needs the manual status control for exceptions like
  cancelling.
- Interview templates: a reusable, shared question bank. Any
  interviewer/admin can browse and create templates (a name + a list of
  question prompts); starting a new interview from one *copies* its
  questions onto that interview, so editing or deleting a template later
  never changes an interview already created from it.
- Interview questions: each question is checked off and annotated inline,
  right on the interview page, no full-page form — the interviewer marks
  it covered and leaves notes, and the candidate submits their own written
  answer to the same question, visible to the interviewer. Both edits are
  scoped to their own fields at the controller layer, not just hidden in
  the UI.
- Candidate tracking: candidate = a `User` with a `CandidateProfile`,
  including a full CV (work experience and education as repeatable,
  add/remove-in-the-browser sections, not flat text fields)
- Feedback: strengths, areas for improvement, a hire/no-hire recommendation,
  and a 1–5 rating per interview, editable inline on the interview page
  without a page reload (Turbo Frames + Turbo Streams)
- Search & discovery: free-text + filtered search (Ransack) and pagination
  (Pagy) on the interviews list, the invites list, and the template list
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

247 examples covering models, policies, and request specs for every
controller action (including authorization boundaries — e.g. an interviewer
can't edit another interviewer's interview, a candidate can't author
feedback, and a candidate answering a question can't sneak in the
interviewer-only `covered`/`notes` fields).

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
 ├─ has_many Interview (as candidate)
 └─ has_many InterviewTemplate (as creator — visible to every interviewer/admin)

InterviewTemplate (name, interview_type, created_by)
 └─ has_many TemplateQuestion (prompt)

Interview (interviewer, candidate, status, interview_type, interview_template)
 ├─ has_one  Feedback (recommendation, rating, strengths, improvements)
 └─ has_many InterviewQuestion (prompt, covered, notes, answer)
      — copied from interview_template's questions at creation time,
        then edited independently per interview from then on
```

### Deployment approach

Not yet deployed (deferred by request during development — this is a
single Docker-deployable Rails app with no external service dependencies,
so it's a `fly launch` / `fly deploy` away using the Dockerfile Rails 8
already generates, with the SQLite file living on a Fly volume).

## Design decisions

The full write-up, including the two design-system iterations I went
through and why, is in [`DESIGN.md`](DESIGN.md). Here's the short version:

- **One app, not two.** Rails renders the pages directly instead of a
  separate backend API plus a JavaScript frontend. It's faster to build
  and still feels snappy, without doubling the work.
- **One login system, with a role attached.** Candidates need to log in to
  see their own feedback later, so they can't just be a row in a table —
  they need a real account like everyone else. Rather than three separate
  tables for admin/interviewer/candidate, there's one user table with a
  role on it, so "the person" and "their login" never fall out of sync.
- **You invite people with a code, not an email link.** The app doesn't
  send emails, so instead of "click this link," you get a one-time code
  to pass along yourself. It expires after a week, only works once, and
  the page that accepts it is rate-limited so it can't be guessed.
- **A simple database, because this doesn't need a heavyweight one.**
  This is a small practice tool, not something with many people hitting
  it at once, so SQLite is enough and it's one less thing to set up.
  Moving to a bigger database later, if it's ever needed, is a small
  config change, not a rewrite.
- **Fixed lists instead of free-typed text** for things like status,
  interview type, and recommendation — so you can't end up with a typo
  like "compelted" quietly breaking a report.
- **The same "what can you see" rule, used everywhere.** Interviewers see
  only their own interviews, admins see everything — and that one rule
  is reused on every screen (the interview list, the dashboard, the
  invites list) instead of being rewritten slightly differently each
  time, which is how those things quietly drift apart.
- **One small reusable bit of code for every "add another row" form.**
  Work history, education, a template's questions, an interview's
  questions — anywhere you can add or remove multiple entries reuses the
  same small piece of code instead of a library or four separate
  one-offs.
- **Anyone can use a template, but only its creator can change it.**
  Every interviewer/admin can browse and start an interview from any
  template — it's a shared library, not a personal one — but only
  whoever made it (or an admin) can edit or delete it.
- **Starting from a template copies it — it doesn't stay linked.**
  Picking a template copies its questions onto the new interview. If
  someone edits or deletes the template later, interviews already made
  from it don't change.
- **The interviewer and the candidate write to the same question, but
  never the same part of it.** The interviewer checks a question off and
  leaves notes; the candidate writes their own answer. They share one
  record, but the app makes sure each side can only ever touch their own
  part — the interviewer can't edit the candidate's answer, and the
  candidate can't check their own answer off.
- **The interview's status updates itself.** Once the candidate submits
  their first answer, the interview moves to "in progress" on its own;
  once feedback is written, it moves to "done." Nobody has to remember to
  flip the status by hand, and a cancelled interview can't be accidentally
  brought back to life by a late answer or late feedback.

## Assumptions made

- **Candidates need a real account, not just a name on a form.** One of the
  requirements is letting candidates look back at their own feedback later,
  and you can't "look back" without logging in — so every candidate has to
  already exist as an invited user before they show up on an interview.
  There's no such thing as an anonymous, un-invited candidate here. The
  same logic applies to interviewers: nobody signs themselves up, someone
  with permission has to invite them first.
- **This is built for one practice group, not many.** I pictured a single
  admin running mock interviews for their own team or community, not
  several unrelated companies sharing one install. That kept things much
  simpler.
- **One good search beats three separate ones.** The brief asked for a way
  to find past interviews and to find participants or feedback. Rather
  than building three different search screens, I put everything into a
  single, well-filtered interviews list — search by title, interviewer,
  candidate, status, type, recommendation, or date range — since in
  practice that one screen answers all three asks at once.
- **A candidate's profile should read like an actual résumé.** Instead of
  one free-text "tell us about yourself" box, it's got real work-history
  and education entries, each with their own dates — closer to what you'd
  hand someone before an interview than a bio paragraph.
- **A candidate's answer is a scratchpad, not a graded submission.** When
  a candidate types an answer to a question inline, I'm treating that as
  them jotting down their thinking for the interviewer to read during the
  conversation — nothing here tries to auto-grade or score whether the
  answer was "right."

## Known limitations

- **Invites still have to be copied and sent by hand.** The app doesn't
  send any emails. When you invite someone, you get a code on screen and
  you have to send it to them yourself — text, Slack, whatever. That's
  fine for a few people, but it gets slow if you're inviting a lot of
  people at once. Sending the code by email automatically would be the
  next thing to add.
- **The database can only handle one thing writing to it at a time.**
  That's fine for how this app is used now, but it would need to change
  before a lot of people could use it at the same time.
- **There's no way to keep separate groups apart.** Right now everyone —
  every interviewer, every candidate — is in one shared pool, and the
  admin can see all of it. That's fine if it's just one team using the
  app, but it wouldn't work if two different companies wanted to use the
  same install without seeing each other's data.
- **You can schedule an interview before someone finishes their profile.**
  New users are asked to fill in their profile right after they join, but
  nothing forces them to — you can still schedule or take part in an
  interview with a blank profile.
- **You can't search inside feedback text.** You can filter feedback by
  hire/no-hire, but you can't search for a word inside someone's written
  feedback (like "system design") to find it later.
- **Status changes don't leave a record.** The interview status now
  updates itself automatically, but there's no log of when it changed or
  why — just the current value.

## Future improvements

- **Send invite codes by email automatically**, instead of everyone
  having to copy and paste them by hand.
- **Tag interviews with skills** (like "Ruby" or "System Design") and show
  trends for each one over time.
- **Let people download things** — reports as CSV or PDF, and a
  candidate's profile as a PDF résumé.
- **Add browser tests that click through the app**, not just tests that
  check the code, to catch UI bugs the current tests might miss.