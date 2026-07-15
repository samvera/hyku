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

## Enabling

The wizard and its optional capabilities are per-tenant Flipflop features
(declared in `config/features.rb`, group `:experimental_features`):

| Feature | Effect |
| --- | --- |
| `deposit_wizard` | Master switch. When off, the wizard routes redirect to the dashboard and the "Guided Deposit" button is hidden. |
| `deposit_wizard_parent_connect` | Lets a depositor nest the work under a parent work — both a start-screen "add to an existing work" path and a review-step section. |
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
  result into a redirect / render / flash. The `Context` concern
  (`app/controllers/concerns/hyrax/deposit_wizard/context.rb`) wires the presenter
  in and provides the `wizard_config` / `wizard_state` shorthands.
- **Presenter**: `Hyku::DepositWizard::Presenter`
  (`app/presenters/hyku/deposit_wizard/presenter.rb`). A request-scoped view-model
  constructed with the controller context, shared by the controller and the views
  (as `deposit_wizard.*`). It owns form building, the stepper rail, admin-set
  options, the flow decisions (`advance_from`, `step_detour`), and the commit-side
  persistence (`deposit`). `#advance_from` returns a `Transition`
  (`app/presenters/hyku/deposit_wizard/transition.rb`) telling the controller
  whether to advance (with an optional notice) or re-render with an alert.
- **Config + state** (`app/services/hyku/deposit_wizard/`):
  - `Hyku::DepositWizard.config` — the swappable configuration seam (see below).
  - `Hyku::DepositWizard::State` — a thin wrapper over `session[:deposit_wizard]`.
- **Views**: `app/views/hyrax/deposit_wizard/` — one template per step plus
  shared partials (`_stepper`, `_nav`, `_admin_set_select`, the review `_extras_*`
  sections).
- **Assets**: `app/assets/javascripts/hyrax/deposit_wizard.js` (progressive
  enhancement) and `app/assets/stylesheets/deposit_wizard/` (SCSS partials).

Persistence runs through the public
`Hyrax::Transactions::Container['work_resource.create']` transaction (via
`Hyrax::Action::CreateValkyrieWork`) and `Hyrax::WorkUploadsHandler`, so
workflow, indexing, and access controls match stock deposit. The wizard works
under both `HYRAX_FLEXIBLE=false` and `HYRAX_FLEXIBLE=true`.

## Steps

The step sequence (`Hyku::DepositWizard::Presenter::STEPS`):

```
start → select_parent → item_start → known_type → files → details → file_meta → review → done
```

Not every step runs on every deposit — several are conditional:

| Step | Purpose | Shown when |
| --- | --- | --- |
| `start` | Path chooser (new / add / standalone) or, in a flat install, the work-type chooser; inline admin-set selection. | Always the entry point. |
| `select_parent` | Pick the parent work to nest under. | Only on the "add" path (`parent_connect`). |
| `item_start` | Sub-flow chooser (known type / guided / batch). | Only when a sub-flow is configured (`enable_batch` or `suggestions`); otherwise skipped straight to `known_type`. |
| `known_type` | Work-type card chooser. | Whenever a type still needs choosing. |
| `files` | Hyrax uploader. | Requires a chosen work type. |
| `details` | Work `ResourceForm` (profile-driven fields, visibility, embargo/lease). | Requires a chosen work type. |
| `file_meta` | Per-file metadata + per-file visibility. | Only when files were uploaded. |
| `review` | Summary, optional connect/share/redirect sections, deposit agreement. | Requires a chosen work type. |
| `done` | Confirmation. | After a successful commit. |

`STEPS_REQUIRING_WORK_TYPE` (`files`, `details`, `file_meta`, `review`) redirect
back to `known_type` if no type has been chosen. The skip/redirect rules live in
`Presenter#step_detour`; forward targets live in the presenter's
`advance_from_<step>` methods; the stepper-rail keys and Back targets live in the
presenter too (`stepper_keys`, `known_type_back_step`).

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
  c.item_types     = %w[PortfolioArtefact PortfolioEvent]
  c.file_pool      = true
  c.file_meta      = true
  c.parent_types   = [Portfolio]
  c.post_commit    = ->(work, wizard_state) { ... }
end
```

The wizard reads the shared instance via `Hyku::DepositWizard.config`; specs
reset it with `Hyku::DepositWizard.reset_config!`.

| Option | Default | Meaning |
| --- | --- | --- |
| `single_admin_set` | `true` | Offer only the primary admin set. |
| `enable_batch` | `false` | Offer the "many files, one type" batch sub-flow (also makes `item_start` appear). |
| `file_pool` | `false` | Offer an upfront shared upload pool at the container level. |
| `file_meta` | `false` | Collect per-file FileSet metadata inline before commit. |
| `container_type` | `nil` | The container work type (class or class name). Presence makes the start screen a new/add/standalone path chooser (`container?`). `nil` is a flat wizard. |
| `item_types` | `nil` | Child/item work types. `nil` falls back to the tenant's enabled work types. |
| `suggestions` | `{}` | File-category → ordered subtype suggestions for the guided sub-flow (also makes `item_start` appear). |
| `parent_types` | `nil` | Work types eligible as parents in the typeahead. `nil` falls back to the tenant's available work types. |
| `post_commit` | `nil` | Callable run after a successful commit, receiving `(work, wizard_state)` — the hook for downstream nesting/fan-out. |

The parent/collection/sharing capabilities are **not** plain config options — they
are the per-tenant Flipflop features above. `Config` exposes `enable_parent_connect`
/ `enable_collection_connect` / `enable_sharing` readers that return an explicit
in-memory override when set (used by specs and apps that set it directly),
otherwise the tenant's Flipflop value. `redirects_available?(form)` combines
Hyrax's redirects gate with a check that the work's schema carries `redirects`.

## Admin-set assistance

When more than one deposit-eligible admin set exists, the start screen shows a
selector whose description and workflow label update as the choice changes.
`Presenter#admin_set_options_for_display` builds each option from Hyrax's
`AdminSetSelectionPresenter` (keeping its `data-*` visibility/release attributes,
which the visibility component enforces on the details step) enriched with the
set's `description` and active-workflow `label`. Admin-set-scoped extra fields
(FlexibleSchema `contexts`, flex mode) flow automatically: the wizard passes the
chosen `admin_set_id` into `ResourceForm.for`, which applies the set's contexts.

## Insertion points for a downstream app

Everything a downstream application needs to customize is a seam; no Hyrax or
Hyku override is required.

- **Configuration** — assign `Hyku::DepositWizard.config` (see above). This is
  the primary seam: container type, item types, parent types, suggestions,
  toggles, and the post-commit hook.
- **Post-commit hook** — `config.post_commit` receives the persisted work and the
  wizard state; use it for container nesting or batch fan-out.
- **Parent nesting** — the persistence layer already honors a top-level
  `parent_id` (seeded by the "add" path or by launch context) through Hyrax's
  `add_to_parent` step. No extra wiring needed to nest under a parent.
- **Launch with context** — `GET deposit_wizard?parent_id=<id>` or
  `?add_works_to_collection=<id>` seeds the matching state slot (each gated by its
  capability), so other entry points can hand off into the wizard with a target
  pre-filled.
- **View overrides** — a consuming application's view-path prepend lets it
  override any step template or partial in `hyrax/deposit_wizard/` for bespoke
  labels or styling.
- **Styling tokens** — the SCSS is scoped under `.deposit-wizard` and driven by
  `--dw-*` CSS custom properties (defined in
  `app/assets/stylesheets/deposit_wizard/_base.scss`), so an app can rebrand by
  overriding the tokens without touching the baseline.

## JavaScript hooks

`deposit_wizard.js` is progressive enhancement keyed off `data-behavior`
attributes (a no-op on non-wizard pages): the file uploader, visibility pills,
per-file master-detail panels, step validity, the review-step connect/share/
redirect controls, the admin-set description, and the parent/collection Select2
typeaheads. The details step additionally carries `data-behavior="work-form"` so
Hyrax's own editor JS binds the autocomplete and controlled-vocabulary fields
exactly as on the stock form.
