# NextRound — Design System: Modern Microsoft (Fluent-inspired)

This is the visual direction for the whole app from this point forward.
Every new screen/component should be built against this doc rather than
default Tailwind look-and-feel (rounded corners, indigo accents, soft
slate-tinted shadows).

## Principle

A clean, modern take on Microsoft's own design language (think Windows
11 / Microsoft 365 web apps) — **not** a retro Windows 95 pastiche. White
surfaces, sharp square corners, a restrained blue accent, generous
whitespace, Segoe UI. Professional and current, with just enough
"Microsoft" signal (the accent blue, the font, the square corners) to read
as intentional rather than a random modern template.

Explicitly avoid: gray 3D bevels, beveled buttons that look "pressed,"
navy title bars, skeuomorphism of any kind. If it looks like an old Windows
dialog box, it's the wrong direction — this is closer to Outlook/Teams/
SharePoint's current web UI.

## Color palette

| Role | Hex | Usage |
|---|---|---|
| Page background | `#FAF9F8` | Body background (Fluent's neutral-lighter) |
| Surface (cards/panels) | `#FFFFFF` | Panels, forms, table backgrounds |
| Border | `#E1DFDD` | Default 1px borders on panels, inputs, table rows |
| Border, stronger | `#D2D0CE` | Dividers that need slightly more contrast |
| Accent (primary) | `#0078D4` | Primary buttons, links, focus rings, active states |
| Accent hover | `#106EBE` | Primary button/link hover |
| Accent pressed | `#005A9E` | Primary button active/pressed |
| Text, primary | `#201F1E` | Default body text |
| Text, secondary | `#605E5C` | Muted/secondary text (labels, timestamps) |
| Text, disabled | `#A19F9D` | Disabled controls |
| Success | `#107C10` | Success text/badges |
| Success background | `#DFF6DD` | Success badge/alert fill |
| Error | `#A80000` | Error text/badges |
| Error background | `#FDE7E9` | Error badge/alert fill |
| Warning | `#8A6116` | Warning text/badges |
| Warning background | `#FFF4CE` | Warning badge/alert fill |

## Typography

```
font-family: "Segoe UI", -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
```

- Segoe UI is Microsoft's actual current system font — this is the single
  biggest "Microsoft" signal in the whole system, more than any color.
- Normal, comfortable web sizing (not the tiny 11-12px of old Windows UI):
  body text ~14px, section headers ~13px bold uppercase-tracked or ~18px
  semibold for page titles — use Tailwind's normal type scale, just paired
  with the Segoe UI stack.
- Weight range: normal (400) body, semibold (600) headings/labels — avoid
  Tailwind's `font-bold`/900-weight extremes.

## Shape

**Sharp square corners everywhere — `border-radius: 0`, no exceptions.**
This is the one deliberate throwback element carried over from the original
retro idea, and it's what keeps this from reading as "just another rounded
SaaS template." Buttons, inputs, panels, badges, cards: all square.

No 3D bevels, no `outset`/`inset` borders. A flat 1px border
(`--border: #E1DFDD`) is enough to define an edge. A very subtle shadow
(`0 1px 2px rgba(0,0,0,0.04)`) is acceptable on elevated surfaces like
dropdowns, but panels/cards on the page should rely on the border, not a
shadow, to read as distinct from the page background.

## Components

### Two layouts: `application` vs `auth`
There is no nav at all on signed-out screens — there's nothing to navigate
to yet, and showing a nav with only a "Log in" button in it is just clutter
around the one thing the page is for. `ApplicationController#layout_for_request`
picks the layout per request: `devise_controller?` (Devise's own sessions
controller) or `controller_name == "claims"` gets `layouts/auth` (no nav,
content vertically/horizontally centered, just the "NextRound" wordmark
above the card); every other controller — which all require authentication
via the global `before_action :authenticate_user!` — gets `layouts/application`
with the full nav. Because of that split, `layouts/application`'s nav
markup can assume `user_signed_in?` is always true and skip the logged-out
branch entirely (Devise's own `authenticate_user!` already no-ops inside
`devise_controller?`, so this doesn't risk a redirect loop on the sign-in
page itself).

Signed-out screens (`devise/sessions/new`, `claims/new`) are built as
stacked `.win-panel` cards: the primary action (the form) first, then a
second card immediately below for the alternate path ("Have an invitation
code? → Claim your invitation" / "Already have an account? → Log in") as
its own full-width button — not a text link buried inside a sentence.
Cross-linking both ways (login page links to claim, claim page links back
to login) means whichever one a user lands on, the other path is one click
away and equally visible.

### Top nav (signed-in only)
White background, 1px bottom border, single row split into two groups by
`justify-between` — brand + nav links (Interviews/Invites/My profile) on the
left, user email + logout on the right. Don't bundle both groups into one
flex container even temporarily (e.g. while prototyping the mobile menu) —
with the hamburger hidden at desktop width, `justify-between` will float a
single combined group toward the middle instead of pinning nav links left
and session right.

Logout uses the danger button variant (`.win-btn-danger` — white
background, red border and text, light red fill on hover) since it's the
one button that ends your session, even though it isn't strictly a
destructive/delete action.

Below the `md` breakpoint, nav links + email + logout collapse behind a
hamburger icon button (`.win-icon-btn`, `md:hidden`) that toggles a stacked
mobile menu panel via a small Stimulus controller
(`app/javascript/controllers/nav_controller.js`, `data-controller="nav"`).
The menu panel's base classes are `hidden md:hidden` — the controller
toggles only the plain `hidden` token, leaving `md:hidden` to permanently
suppress the mobile panel at desktop widths regardless of toggle state.

### Panels / cards
White background, 1px `--border` border, square corners, a header row
(semibold text, bottom border) when the panel needs a label — this is the
same structural idea as before, just flat instead of beveled.

### Buttons
- Primary: solid accent blue background, white text, square corners, no
  border. Hover darkens to `--accent-hover`, active/pressed to
  `--accent-pressed`. No transition timing needed to be fancy — a simple
  `transition-colors` is fine here (unlike the retro version, we're not
  banning all transitions, just gratuitous ones).
- Secondary/default: white background, 1px `--border` border, dark text.
  Hover: very light gray background tint.
- Danger (`.win-btn-danger`): white background, red border and text
  (`--error`), hover fills with the light red tint, active/pressed goes
  solid red with white text. Used for session logout; reserve for anything
  that ends/undoes state, not for ordinary secondary actions.
- Focus state: 2px solid accent-blue outline (a real Fluent/Office pattern),
  not a soft glow ring.

### Icon buttons
Two variants, both square, both with the same 2px blue focus outline:
- **Neutral** (`.win-icon-btn`) — transparent background, muted gray icon,
  light gray background + accent-blue icon on hover. Used for secondary
  inline actions: editing an existing interview/feedback/profile
  (`icon_edit_button`, Lucide pencil icon).
- **Primary** (`.win-icon-btn-primary`) — solid accent-blue background,
  white icon, darkens on hover/press like the primary button. Used for
  "create a new X" actions instead of a labeled button (`icon_add_button`,
  Lucide plus icon) — e.g. "New interview," "New invite." Prefer this over
  a text button for top-of-list create actions; keep text links (like
  "Invite someone else" in a footer nav row) as plain links, not buttons.

### Form inputs
White background, 1px `--border` border, square corners. On focus: border
becomes 2px accent blue (no glow/shadow ring needed).

### Repeatable CV-style sections (nested attributes)
For a `has_many` association edited inline on a parent form (e.g. a
candidate's work experience / education entries), use the `nested-form`
Stimulus controller (`app/javascript/controllers/nested_form_controller.js`)
rather than a gem (no Cocoon dependency) — it's the standard "Rails nested
form without a gem" recipe:

- Each repeatable section gets its own `data-controller="nested-form"`
  wrapper with a `data-nested-form-target="container"` (existing rows,
  rendered server-side via `f.fields_for`) and a `<template
  data-nested-form-target="template">` holding one blueprint row built from
  a brand-new unsaved record with `child_index: "NEW_RECORD"`.
- Each row is its own `.win-panel` card with a "Remove" button
  (`.win-btn-danger`, `data-action="nested-form#remove"`) — existing rows
  get soft-removed (hidden + `_destroy` hidden field set to `"1"`, so the
  server actually deletes them on save), brand-new not-yet-saved rows
  (`data-new-record="true"`) just get removed from the DOM outright.
- The row's own field markup lives in one shared partial (e.g.
  `_work_experience_fields`) so the container's real rows and the
  template's blueprint row render identically — never write the fields
  twice.
- `reject_if: :all_blank` on `accepts_nested_attributes_for` means the form
  can always show one extra blank row for "the next entry" without extra
  JS bookkeeping — if it's left empty on submit, it's silently discarded
  rather than raising a validation error.
- Reused twice more beyond the original CV use: a template's question list
  (`interview_templates/_form`) and, per interview, the interviewer's bulk
  question editor (`interviews/_form`) — same recipe, a single `prompt`
  field instead of a multi-field CV row.

### Per-row inline editing (Turbo Frame per record)
The Feedback card's edit-in-place pattern (a single `turbo_frame_tag
:feedback`, swapped between `feedbacks/_card` and `feedbacks/edit` on save)
extends to a *list* of records the same way: each interview question row on
the interview show page (`interview_questions/_question_row`) is its own
`turbo_frame_tag dom_id(question)`, and its edit form
(`interview_questions/edit`) is wrapped in that same frame id. Clicking a
row's edit icon swaps just that row into its edit form; saving replaces
just that frame via `turbo_stream.replace(dom_id(question), ...)` from
`InterviewQuestionsController#update`. "Cancel" is a plain link back to the
interview's full show page rather than a second turbo_stream action —
because the frame id on the show page matches, Turbo automatically
extracts just that one `<turbo-frame>` from the full-page response and
swaps it in.

This controller also demonstrates the pattern for "two roles write
different fields on the same record": `InterviewQuestionPolicy#update?`
authorizes either the owning interviewer/admin *or* the candidate on that
interview, while `InterviewQuestionsController#interview_question_params`
separately switches which attributes are permitted — `covered`/`notes` or
`answer` — based on `current_user.candidate?`. The authorization check and
the field-level write boundary are kept as two distinct checks on purpose,
so neither role can widen its own write access by tampering with the form.

### Candidate profile read view (`candidate_profiles/_cv`)
The candidate profile's read-only view is deliberately laid out like an
actual CV/résumé rather than a generic key-value `<dl>`: a header block
(`.cv-header`) with name, current role, contact line, and target-role/
years-of-experience as `.win-badge` chips, then Summary/Work
experience/Education as labeled sections. Each work/education entry is a
`.cv-entry` — a left border accent (2px `--border`) with the title/degree
bold on the left and the date range (`date_range_for` helper, "Mon YYYY –
Mon YYYY" or "– Present") right-aligned on the same line. This partial is
shared between the candidate's own "My profile" page and an admin/inviter
viewing a claimed candidate's profile from the invite show page — don't
fork it per caller, both contexts want the same CV rendering.

### Tables / lists
White background, header row with light gray background + semibold text,
1px border between rows (not full cell borders), row hover = very light
blue tint (`#F3F9FD`).

### Tables / lists
White background, header row with light gray background + semibold text,
1px border between rows (not full cell borders), row hover = very light
blue tint (`#F3F9FD`).

**Every list page shares the same container width (`max-w-6xl`).** Don't
size each index page's container to its own table's column count —
navigating between e.g. Interviews and Invites with different widths reads
as a layout jump/glitch even though each page looks fine in isolation.
Wrap the table in `overflow-x-auto` so it scrolls horizontally rather than
breaking the page on narrow screens, and hide less-essential columns below
`sm`/`md` with `hidden sm:table-cell`/`hidden md:table-cell` (matched on
both the `<th>` and its column's `<td>`s) rather than shrinking the
container.

### Search/filter forms
Every list page's search form goes through the shared
`shared/_search_form` partial rather than each page hand-rolling its own
`search_form_for` block — it's rendered as a **partial-as-layout** so each
page still supplies its own filter fields:

```erb
<%= render layout: "shared/search_form", locals: { q: @q, url: interviews_path } do |f| %>
  <div>
    <%= f.label :title_cont, "Search", class: "win-field-label" %>
    <%= f.search_field :title_cont, class: "win-input" %>
  </div>
<% end %>
```

The partial owns the `.win-panel` wrapper styling and the Search/Clear
buttons; the page's block receives the Ransack form builder (`f`) via
`yield f` inside the partial and renders whatever fields make sense for
that model. Don't put example `<%= %>`/`<% end %>` snippets inside an ERB
comment (`<%# %>`) in the partial itself — a literal `%>` inside the
comment text closes it early and leaves a stray `<% end %>` behind,
which is a real syntax error we hit once already.

Ransack's `_eq` predicate on an integer/enum column casts the raw param
with `.to_i` — it does **not** translate a Rails enum's string label to
its integer value the way `ActiveRecord::Base#where(status: "cancelled")`
does. Every enum filter `<select>` must submit the enum's integer value,
e.g. `Interview.statuses.map { |label, value| [label.humanize, value] }`,
**not** `.keys.map { |s| [s.humanize, s] }` — the latter silently filters
on the wrong records (a non-numeric string like `"cancelled"` casts to
`0`, matching whichever enum member happens to be value `0`).

### Pagination
Shared `shared/_pagination` partial (`locals: { pagy: @pagy }`) wraps
Pagy's `@pagy.series_nav` and only renders when there's more than one
page. Pagy 43.x uses a single `Pagy::Method` mixin
(`include Pagy::Method` in `ApplicationController`, `@pagy, @records =
pagy(scope)`) rather than the older `Pagy::Backend`/`Pagy::Frontend`
split — the nav is called directly on the pagy instance
(`@pagy.series_nav`), not a `pagy_nav(@pagy)` view helper. Styled via a
`.series-nav` CSS block in `@layer components`.

### Status badges
Small square (not pill) tags: colored text on a light tint background
matching the semantic color table above (success/error/warning), no border
needed, no `rounded-full`.

### Alerts / flash messages
Light tint background matching the semantic color (success green tint /
error red tint), left border accent in the solid color (4px solid), square
corners, no drop shadow.

## Implementation notes

- Same component vocabulary as before, just redefined: `.win-btn`,
  `.win-panel`, `.win-input`, `.win-badge`, `.win-table`, `.win-alert`
  classes stay (no need to rename every view that already migrated), but
  their CSS definitions in `app/assets/tailwind/application.css` are now
  the flat/modern version described here, not the beveled one.
- `Win95FormBuilder` is renamed `FluentFormBuilder`
  (`app/form_builders/fluent_form_builder.rb`) to match.
- Retrofit order: shared layout/nav → `FluentFormBuilder` → status badges →
  interview/feedback cards → everything else (same order as before, just
  continuing under the corrected direction).

### CSS cascade layers — required for every new custom class

**Every custom `.win-*` class must be declared inside `@layer components {}`**
in `app/assets/tailwind/application.css`. Tailwind v4 puts its own utilities
in `@layer utilities`, and CSS cascade layers resolve strictly by layer
order *before* specificity or source order — so any plain, unlayered CSS
rule always beats a rule inside a layer, no matter how the selectors compare.

This bit us for real: `.win-icon-btn { display: inline-flex }` was declared
unlayered, so it permanently beat `.md\:hidden { display: none }` on the
same element even inside the `@media (min-width: 768px)` block — the
hamburger button stayed visible on desktop no matter what. The fix was
wrapping all component classes in `@layer components`, which is lower
priority than Tailwind's `@layer utilities`, restoring the expected
"utilities can always override components" behavior.

The one deliberate exception is the global `* { border-radius: 0 !important; }`
reset, which stays unlayered on purpose — it's meant to unconditionally beat
everything, including any future utility.
