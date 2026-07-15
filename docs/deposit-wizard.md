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

## Steps

The step sequence (`Hyku::DepositWizard::Presenter::STEPS`):

```
start → select_parent → item_start → known_type → files → details → file_meta → review → done
```

Not every step runs on every deposit — several are conditional:

| Step | Purpose | Shown when |
| --- | --- | --- |
| `start` | Path chooser (new / add / standalone) when the start relationship path is offered, otherwise the work-type chooser; inline admin-set selection. | Always the entry point. |
| `select_parent` | Pick the parent work to nest under. | Only on the "add" path — when parent-connect is on and its placement includes the start edge. |
| `item_start` | An override seam for a downstream item sub-flow; the built-in screen just continues to the work-type chooser. | Skipped straight to `known_type` unless a sub-flow is configured. |
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
  c.parent_types   = [Portfolio]
  c.post_commit    = ->(work, wizard_state) { ... }
end
```

The wizard reads the shared instance via `Hyku::DepositWizard.config`; specs
reset it with `Hyku::DepositWizard.reset_config!`.

| Option | Default | Meaning |
| --- | --- | --- |
| `container_type` | `nil` | The container work type (class or class name). Presence makes the start screen a new/add/standalone path chooser (`container?`). `nil` is a flat wizard. |
| `parent_types` | `nil` | Work types eligible as parents in the typeahead. `nil` falls back to the tenant's available work types. |
| `parent_connect_placement` | `:both` | Where parent-connect offers to attach a parent: `:both`, `:start` (only the up-front path), `:review` (only the review section), or `:none`. Only takes effect when parent-connect is enabled. |
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
Hyku override is required.

- **Configuration** — assign `Hyku::DepositWizard.config` (see above). This is
  the primary seam: container type, parent types, and the post-commit hook.
- **Post-commit hook** — `config.post_commit` receives the persisted work and the
  wizard state; use it for container nesting.
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
