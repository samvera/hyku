# Guided Deposit Wizard

The guided deposit wizard is a multi-step alternative to Hyrax's single-page
tabbed deposit form. It walks a depositor through work-type selection, file
upload, metadata, per-file metadata, and review, then commits through the same
public Hyrax create transaction — so a work created by the wizard is
indistinguishable from one created by the stock form.

The wizard is additive: the stock deposit form is untouched, and the wizard is
off by default behind a feature flag. It is designed as a **generic Hyku
feature** with **seams a downstream application** can configure and extend
without forking.

## Contents

- [Enabling](#enabling)
- [Architecture](#architecture)
- [Steps and the Flow](#steps-and-the-flow)
  - [The progress rail](#the-progress-rail)
  - [Error handling](#error-handling)
- [Configuration](#configuration)
- [Admin-set assistance](#admin-set-assistance)
- [Insertion points for a downstream app](#insertion-points-for-a-downstream-app)
  - [Configuration](#configuration-1)
  - [Step flow](#step-flow)
    - [How a step is defined](#how-a-step-is-defined)
  - [Post-commit hook](#post-commit-hook)
  - [Parent nesting](#parent-nesting)
  - [Launch with context](#launch-with-context)
  - [View overrides and styling](#view-overrides-and-styling)
- [JavaScript hooks](#javascript-hooks)

## Enabling

The wizard and its optional capabilities are per-tenant Flipflop features
(declared in `config/features.rb`, group `:deposit_wizard`):

| Feature | Effect |
| --- | --- |
| `deposit_wizard` | Master switch. When off, the wizard routes redirect to the dashboard and the "Guided Deposit" button is hidden. |
| `deposit_wizard_parent_connect` | Lets a depositor nest the work under a parent work. Where the offer appears — the start-screen "add to an existing work" path, the review-step section, or both — is set by `parent_connect_placement` (see Configuration). |
| `deposit_wizard_collection_connect` | Lets a depositor add the work to one or more collections on the review step. |
| `deposit_wizard_sharing` | Lets a depositor grant per-user / per-group access on the review step. |

Vanity-URL redirects on the review step are gated separately by Hyrax's own
`redirects_active?` (its boot flag plus `Flipflop.redirects?`) **and** the work's
schema carrying a `redirects` attribute — not by a wizard-specific flag.

The dashboard entry point is a "Guided Deposit" button rendered in
`app/views/hyrax/my/works/_deposit_actions.html.erb`, shown only when
`Flipflop.deposit_wizard?` is true.

## Architecture

A thin controller drives a sequence of server-rendered steps, holding state in
the session between steps. Almost all of the wizard's logic lives on a presenter
object the controller and views share; the controller keeps only its HTTP
boundary. It wraps — does not replace — Hyrax's create machinery.

- **Controller**: `Hyrax::DepositWizardController`
  (`app/controllers/hyrax/deposit_wizard_controller.rb`). Actions: `start`,
  `show` (per step), `update` (advance), `commit`, plus the AJAX endpoints
  `parent_options` (parent typeahead) and `save_extras` (review-step autosave).
  Each action reads params, calls the presenter for the decision, and turns the
  result into a redirect / render / flash. It memoizes the presenter and exposes
  `wizard_config` / `wizard_state` shorthands; there are no controller concerns.
- **Presenter**: `Hyku::DepositWizard::Presenter`
  (`app/presenters/hyku/deposit_wizard/presenter.rb`). A request-scoped view-model
  constructed with the controller context, shared by the controller and the views
  (as `deposit_wizard.*`). It owns form building, admin-set options, and the
  commit-side persistence (`deposit`), and orchestrates each step's `advance_from`
  (read params → mutate state → return a `Transition`). It delegates the *flow*
  itself — order, skips, prerequisites, next/back/detour, and the stepper rail —
  to the configured `Flow` (see "Steps and the Flow"). `#advance_from` returns a
  `Transition` (`app/models/hyku/deposit_wizard/transition.rb`) telling the
  controller whether to advance (with an optional notice) or re-render with an
  alert.
- **Domain and value objects** (`app/models/hyku/deposit_wizard/`) — the wizard's
  plain-Ruby collaborators, none of which persist to a database:
  - `Hyku::DepositWizard::Config` — static deployment settings (container type,
    parent/item types, flow, post-commit hook), reached through the swappable
    module-level singleton `Hyku::DepositWizard.config` (see below).
  - `Hyku::DepositWizard::State` — a thin wrapper over `session[:deposit_wizard]`.
  - `Hyku::DepositWizard::Flow` — the step sequence as data plus its navigator (a
    swappable `Config#flow`); see "Steps and the Flow".
  - `Hyku::DepositWizard::VisibilityPolicy` — a policy object deriving the allowed
    visibility options from an admin set's rules (see "Admin-set assistance").
  - `Hyku::DepositWizard::Transition` — the result object for advancing a step
    (advance vs. re-render); `Hyku::DepositWizard::VisibilityFields` — the value
    object the visibility partial renders.
- **Views**: `app/views/hyrax/deposit_wizard/` — one template per step, shared
  chrome partials (`_stepper`, `_nav`, `_page_header`, `_step_title`), and
  step-specific partials (the start `_admin_set_select`, the `file_meta`
  `_file_sidebar` / `_file_panel`, the review `_review_summary` /
  `_review_agreement` / `_extras_*` sections).
- **Assets**: `app/assets/javascripts/hyrax/deposit_wizard.js` (progressive
  enhancement) and `app/assets/stylesheets/deposit_wizard/` (SCSS partials).

Persistence runs through the public
`Hyrax::Transactions::Container['work_resource.create']` transaction (via
`Hyrax::Action::CreateValkyrieWork`) and `Hyrax::WorkUploadsHandler`, so
workflow, indexing, and access controls match stock deposit. The wizard works
under both `HYRAX_FLEXIBLE=false` and `HYRAX_FLEXIBLE=true`.

## Steps and the Flow

The step sequence, skips, prerequisites, and progress rail are described by a
single **`Hyku::DepositWizard::Flow`** (`app/models/hyku/deposit_wizard/flow.rb`)
— an ordered list of `Step` value objects plus a navigator. The presenter delegates
every flow question to `config.flow`, so ordering lives in one place rather than
scattered across the presenter and views. The default sequence:

```
start → select_parent → item_start → known_type → files → details → file_meta → review → done
```

Each `Step` declares its own rules; the navigator computes the rest:

- **`skip_if`** — a step not applicable in the current state is skipped by
  next/back and detoured away from if visited directly. `on_skip: :entry` bounces
  an invalid direct visit back to the start (used by `select_parent` off the add
  path); the default passes through to the next visible step (used by `item_start`
  with no sub-flow).
- **`requires`** — named state prerequisites. A step whose prerequisite is unmet
  detours to the step that fulfills it. The only prerequisite today is
  `:work_type` (fulfilled by `known_type`); the admin set is auto-resolved, so it
  is never a prerequisite.
- **Back** is the previous visible step (`Flow#back_before`), so views never name
  their predecessor. **Forward** is the next visible step (`Flow#next_after`).
- **Detours** (`Flow#detour_for`) replace the old per-step redirect rules.

| Step | Purpose | Shown when |
| --- | --- | --- |
| `start` | Path chooser (new / add / standalone) when the start relationship path is offered, otherwise the work-type chooser; inline admin-set selection. | Always the entry point. |
| `select_parent` | Pick the parent work to nest under. | Only on the "add" path — when parent-connect is on and its placement includes the start edge. |
| `item_start` | An override seam for a downstream item sub-flow; the built-in screen just continues to the work-type chooser. | Shown only when a guided sub-flow is configured (`config.suggestions` present); otherwise skipped straight to `known_type`. |
| `known_type` | Work-type card chooser. | Whenever a type still needs choosing. |
| `files` | Hyrax uploader. | Always available — upload has no prerequisite, so files may be added before a work type is chosen. |
| `details` | Work `ResourceForm` (profile-driven fields, visibility, embargo/lease). | Requires a chosen work type. |
| `file_meta` | Per-file metadata + per-file visibility. | Only when files were uploaded. |
| `review` | Summary, optional connect/share/redirect sections, deposit agreement. | Requires a chosen work type. |
| `done` | Confirmation. | After a successful commit. |

### The progress rail

The stepper rail is its own ordered phase list (`Flow#rail_keys`, default
`%i[parent type upload detail file_detail review]`) — deliberately independent of
the step sequence, because several steps collapse into one phase
(`start`/`item_start`/`known_type` all map to `:type`) and an app may want a
different display order than the walk order. A phase renders only when a visible
step maps to it. Reorder the rail by setting a different `rail_keys` list on the
flow.

### Error handling

Validation and transaction failures surface a multi-line flash rather than
silently re-rendering (the presenter reports the messages; the controller flashes
them):

- **Details step** — a field the form validator rejects (for example a
  `video_embed` that is not a YouTube/Vimeo embed URL) re-renders `details` with
  the entered values preserved and the specific errors listed.
- **Review step / commit** — a form-validation failure, or a transaction failure
  such as a redirect-path collision (only detectable at commit), re-renders
  `review` with an explanation. Transaction reasons are translated via
  `hyku.deposit_wizard.errors.commit.<reason>` where a translation exists.

## Configuration

Downstream apps replace the shared config instance (typically in an initializer):

```ruby
Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new do |c|
  c.container_type = Portfolio
  c.parent_types   = [Portfolio]
  c.post_commit    = ->(work, wizard_state) { ... }
end
```

The wizard reads the shared instance via `Hyku::DepositWizard.config`; specs
reset it with `Hyku::DepositWizard.reset_config!`.

| Option | Default | Meaning |
| --- | --- | --- |
| `container_type` | `nil` | The container work type (class or class name). Presence makes the start screen a new/add/standalone path chooser (`container?`). `nil` is a flat wizard. |
| `item_types` | `nil` | Restricts the work types the type chooser offers, intersected with what the user is authorized to deposit (it narrows, never widens). `nil` offers all authorized types. |
| `parent_types` | `nil` | Work types eligible as parents in the typeahead. `nil` falls back to the tenant's available work types. |
| `parent_connect_placement` | `:review` | Where parent-connect offers to attach a parent: `:both`, `:start` (only the up-front path), `:review` (only the review section), or `:none`. Only takes effect when parent-connect is enabled. |
| `suggestions` | `{}` | A guided sub-flow map (uploaded-file kind → offered sub-types) for the `item_start` step. When present (`item_start_offers_choice?`), the `item_start` step is shown; empty skips straight to the work-type chooser. |
| `flow` | `Flow.default` | The ordered step sequence (a `Hyku::DepositWizard::Flow`). Assign a reshaped flow to add, remove, or reorder steps (see [Step flow](#step-flow)). |
| `post_commit` | `nil` | Callable run after a successful commit, receiving `(work, wizard_state)` — the hook for downstream nesting/fan-out. |

The parent/collection/sharing capabilities are **not** config options — they are
the per-tenant Flipflop features above, read **live** on every request through
`config.capabilities` (`parent_connect?` / `collection_connect?` / `sharing?`), a
small module nested in `Config`. They are never stored on the config and cannot be
overridden in memory, so toggling a flag takes effect immediately. Static
deployment settings (the table above) live on `Config` itself; the capability
on/off is always the flag. `parent_connect_placement` (static) then decides which
of the two parent-connect edges appears when the flag is on
(`parent_connect_on_start?` / `parent_connect_on_review?`).
`redirects_available?(form)` combines Hyrax's redirects gate with a check that the
work's schema carries `redirects`.

## Admin-set assistance

When more than one deposit-eligible admin set exists, the start screen shows a
selector whose description and workflow label update as the choice changes.
`Presenter#admin_set_options_for_display` builds each option from Hyrax's
`AdminSetSelectionPresenter`, carrying its permission-template `data-*`
(visibility/release rules) and enriching it with a `description` and workflow
label from `Hyku::DepositWizard::AdminSetDescription`.

Those `data-*` rules drive what visibility options the **details** step offers.
`Presenter#visibility_policy` reads the selected set's data through
`Hyku::DepositWizard::VisibilityPolicy` (a server-side port of Hyrax's client-side
`VisibilityComponent#applyRestrictions`), and the `_visibility` partial renders
only the allowed options (forcing/locking the embargo date when the set requires a
specific release date). This is display-side enforcement, matching stock Hyrax.

Admin-set-scoped extra fields (FlexibleSchema `contexts`, flex mode) flow
automatically: the wizard passes the chosen `admin_set_id` into `ResourceForm.for`,
which applies the set's contexts.

## Insertion points for a downstream app

Everything a downstream application needs to customize is a seam; no Hyrax or
Hyku file is overridden, prepended, or decorated.

**Where this code goes.** `Hyku::DepositWizard.config` is a swappable
module-level singleton (`app/models/hyku/deposit_wizard.rb`); the wizard reads
it fresh on each request. A downstream app *replaces* it — it does not patch the
wizard. Hyku ships **no** `deposit_wizard` initializer (a plain install runs the
default `Config`), so the app **creates a new initializer**, conventionally
`config/initializers/deposit_wizard.rb`, and assigns the config there. All the
Ruby examples below live in that one initializer.

In a **knapsack** (e.g. Enact), that initializer lives in the knapsack's own
`config/initializers/`. The knapsack engine loads its initializers
`after: :load_config_initializers` (after Hyku's), so the knapsack's assignment
reliably wins over Hyku's default without any load-order tricks.

### Configuration

The primary seam: assign a `Config` for container type, parent types, work-type
restriction, and the post-commit hook. In
`config/initializers/deposit_wizard.rb`:

```ruby
Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new do |c|
  c.container_type = "Portfolio"
  c.parent_types   = %w[Portfolio]
  c.item_types     = %w[PortfolioArtefact PortfolioEvent PortfolioLiterature]
  c.post_commit    = ->(work, state) { NestUnderPortfolio.call(work, state) }
end
```

### Step flow

Reshape `config.flow` (assigned in the same initializer) to add, remove, or
reorder steps without touching controller or view code. There is no in-place
mutation helper — build a new steps array from `Flow.default_steps` and pass it to
`Flow.new`.

#### How a step is defined

A step is a `Flow::Step` value object (keyword-init). Every field is optional
except `name`; the navigator derives all sequencing from these fields, so a step
declares its own rules and never names its neighbors.

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | String | The step identifier. Must match a route step and a view template `app/views/hyrax/deposit_wizard/<name>.html.erb`. |
| `requires` | Array of symbols | Named state prerequisites. Before rendering, the navigator detours to the step that fulfills the first unmet one. Only `:work_type` is defined today (see below). Omit for a step with no prerequisite. |
| `skip_if` | `->(state, config)` | When it returns true the step is skipped: passed over by next/back and detoured past if visited directly. Omit for an always-shown step. |
| `on_skip` | `:entry` or nil | How a *direct* visit to a skipped step resolves. `:entry` bounces back to the first step (used by `select_parent` off the add path); nil (default) passes through to the next visible step (used by `item_start`). |
| `terminal` | Boolean | Marks a non-navigable endpoint reached by commit, not by advancing (`done`). Terminal steps are excluded from next/back and the rail. |
| `rail_key` | Symbol | Which progress-rail phase this step maps to. Several steps can share one key and collapse into a single phase (`start`/`item_start`/`known_type` all → `:type`). Omit to keep the step off the rail. |
| `rail_if` | `->(state, config)` | Extra condition for the rail phase to show (independent of `skip_if`) — e.g. `:parent` only on the add path, `:file_detail` only when files exist. Omit for "show whenever a visible step maps to this key". |
| `icon` / `label_key` | String | The rail phase's Font Awesome icon and i18n label suffix (`hyku.deposit_wizard.stepper.item.<label_key>`). Set on whichever step of a collapsed phase should supply the rail's icon/label. |

**Prerequisites are a registry, not free-form.** `requires:` entries are looked up
in `Flow::PREREQUISITES`, which maps each prerequisite to a `met` predicate and the
`step` to detour to when unmet:

```ruby
PREREQUISITES = {
  work_type: { met: ->(state, _config) { state.work_type.present? }, step: 'known_type' }
}.freeze
```

To add a *new* prerequisite (e.g. one your inserted step needs), extend this
registry — a bare `requires: %i[my_thing]` with no matching entry is ignored, not
enforced. `work_type` is the only prerequisite today, and the admin set is
auto-resolved, so it is intentionally not one.

Because `files` has no work-type prerequisite, a step may run *before* a type is
chosen — e.g. one that infers the work type from an uploaded file. This inserts a
`guided_confirm` step after `files`:

```ruby
Hyku::DepositWizard.config = Hyku::DepositWizard::Config.new do |c|
  flow  = Hyku::DepositWizard::Flow
  steps = flow.default_steps
  files_at = steps.index { |s| s.name == "files" }
  steps.insert(files_at + 1, flow::Step.new(name: "guided_confirm"))

  c.flow = flow.new(steps)
end
```

Each step name must have a matching view template at
`app/views/hyrax/deposit_wizard/<name>.html.erb` (added in the app or knapsack via
its view-path prepend). A step that reads state to decide whether it applies uses
`skip_if` (skipped by next/back and detoured past when visited directly):

```ruby
flow::Step.new(name: "guided_confirm",
               skip_if: ->(state, _config) { state.uploaded_file_ids.blank? })
```

To reorder only the progress rail (independent of the walk order), pass
`rail_keys`:

```ruby
c.flow = flow.new(flow.default_steps,
                  rail_keys: %i[type parent upload detail file_detail review])
```

### Post-commit hook

`config.post_commit` receives the persisted work and the wizard state after a
successful commit — the seam for container nesting or fan-out:

```ruby
c.post_commit = lambda do |work, state|
  parent = Hyrax.query_service.find_by(id: state.parent_id)
  # nest, notify, enqueue follow-up jobs, etc.
end
```

### Parent nesting

The persistence layer already honors a top-level `parent_id` (seeded by the "add"
path or by launch context) through Hyrax's `add_to_parent` step, so nesting under
a parent needs no extra wiring — set `parent_types` and enable the
`deposit_wizard_parent_connect` feature.

### Launch with context

Other entry points can hand off into the wizard with a target pre-filled by
passing a context param; each is gated by its matching capability:

```erb
<%= link_to "Deposit into this collection",
    main_app.deposit_wizard_path(add_works_to_collection: collection.id) %>

<%= link_to "Attach a child work",
    main_app.deposit_wizard_path(parent_id: parent_work.id) %>
```

### View overrides and styling

A consuming application's view-path prepend overrides any step template or
partial in `hyrax/deposit_wizard/` for bespoke labels or styling. The SCSS is
scoped under `.deposit-wizard` and driven by `--dw-*` CSS custom properties
(defined in `app/assets/stylesheets/deposit_wizard/_base.scss`), so an app can
rebrand by overriding the tokens without touching the baseline.

## JavaScript hooks

`deposit_wizard.js` is progressive enhancement keyed off `data-behavior`
attributes (a no-op on non-wizard pages): the file uploader, visibility pills,
per-file master-detail panels, step validity, the review-step connect/share/
redirect controls, the admin-set description, and the parent/collection Select2
typeaheads. The details step additionally carries `data-behavior="work-form"` so
Hyrax's own editor JS binds the autocomplete and controlled-vocabulary fields
exactly as on the stock form.
