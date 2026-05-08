# Redirects Feature — Automated Test Coverage Map

Cross-reference of the [manual testing checklist](https://github.com/notch8/palni_palci_knapsack/issues/649)
against the Hyku RSpec specs on branch `test/redirects-specs`.

**Legend:**
- [x] = covered by a Hyku spec (spec file noted)
- [~] = partially covered or indirectly covered (explanation noted)
- [ ] = manual testing only (not automated in Hyku; may be covered by upstream Hyrax specs)

---

## Pre-flight setup (both modes)

- [ ] **App-level config** — set `HYRAX_REDIRECTS_ENABLED=true` and reboot.
- [ ] **Flipflop** — toggle `redirects` on in admin UI; verify per-tenant scoping.
- [ ] **Migrations run** — `hyrax_redirect_paths` table exists with correct indexes.
- [ ] **Reindex** — `hyrax:solr:reindex_everything` populates `redirects_path_ssim`.
- [ ] **Pick a flex mode** — confirm `HYRAX_FLEXIBLE` env var state.

> These are environment setup steps, not behavioral assertions. Not automatable as unit tests.

---

## Pass 1: `HYRAX_FLEXIBLE` unset (default schema mode)

- [ ] Boot with `HYRAX_REDIRECTS_ENABLED=true`, confirm `Hyrax::Work.attribute_names.include?(:redirects)` → true.
- [ ] Boot with `HYRAX_REDIRECTS_ENABLED` unset, confirm attribute absent.

> Covered by upstream Hyrax specs (allinson/dassie CI apps). Hyku's `rails_helper.rb` hardcodes `HYRAX_FLEXIBLE=false`, so attribute presence would need a separate CI job to test under flexible mode.

---

## Pass 2: `HYRAX_FLEXIBLE=true` (m3 profile-driven schema)

### m3 profile setup

- [ ] Add `redirects` property to m3 profile and save successfully.

### m3 profile validation matrix

- [ ] Flipflop off, property absent → silent.
- [ ] Flipflop off, property present → warning.
- [ ] Flipflop on, property absent → error.
- [ ] Flipflop on, property without `type: hash` → error.
- [ ] Flipflop on, `available_on.class` lists no declared class → error.
- [ ] Flipflop on, property present and complete → silent.

> All upstream Hyrax validation behavior. Covered by Hyrax's `RedirectsValidator` spec and `FlexibleSchemaValidators::RedirectsValidator` spec.

### Config-off interaction with stale m3 properties

- [ ] Config off, profile declares `redirects` → warning on save.
- [ ] Config off, records loaded via M3SchemaLoader still expose `redirects` attribute.

> Upstream Hyrax behavior.

### Flexible-mode attribute presence

- [ ] Work/collection classes expose `redirects` attribute when config + Flipflop + profile property are all set.

> Upstream Hyrax behavior tested by the `allinson` CI app.

---

## Shared body

### Form: adding redirects to a work

- [ ] Edit work, find Redirects tab, add path, save.
- [ ] Reload edit form, confirm entry persists.
- [ ] Save full URL, confirm normalized to path-only.
- [ ] Save path with trailing slash, confirm stored without.
- [ ] Mark entry canonical, save, reload, confirm flag persists.

> Upstream Hyrax form behavior. The Redirects tab on **work** forms comes from Hyrax's `form_tabs_for` helper + `_form_redirects.html.erb` partial — no Hyku override involved.

### Form: adding redirects to a collection (Hyku-specific)

- [x] Edit collection, find Redirects tab — **`_form_redirects_tab_spec.rb`**: verifies the Aliases tab link and `div#redirects` pane render when feature is active and model supports redirects.
- [~] Verify `save_collection_thumbnail` still works — **`collection_update_decorator_spec.rb`**: verifies the step is present in `DEFAULT_STEPS` at the correct position after `save_collection_logo`. Does not exercise the step end-to-end with a real thumbnail upload.
- [~] Verify collection banner/logo upload still works — **`collection_update_decorator_spec.rb`**: verifies `save_collection_banner` and `save_collection_logo` steps are preserved in the decorated step list. Does not exercise actual file upload.

### Validation rules (form-level)

- [ ] Blank path → error.
- [ ] Bad format (whitespace, `?`, `#`, no leading `/`) → error.
- [x] Reserved Hyrax prefix (`/admin`, `/dashboard`, `/catalog`, `/concern`) → reserved-prefix error — **`reserved_prefixes_spec.rb`**: confirms these prefixes are in the reserved list.
- [x] Reserved Hyku prefix (`/authorities`, `/bookmarks`, `/browse`, `/exporters`, `/identity_providers`, `/importers`, `/jobs`, `/single_signon`, `/status`, `/sword`) → reserved — **`reserved_prefixes_spec.rb`**: confirms all 10 Hyku-added prefixes are present.
- [~] `/single_signon/foo` → reserved — **`reserved_prefixes_spec.rb`**: confirms `/single_signon` is in the prefix list. Prefix-matching logic (`path == prefix || path.start_with?("#{prefix}/")`) is upstream `RedirectValidator` behavior.
- [~] `/single_signon_admin` → accepted — **`reserved_prefixes_spec.rb`**: confirms `/single_signon` is the prefix (not `/single_signon_admin`). Prefix-matching logic is upstream.
- [ ] Intra-record duplicate → error.
- [ ] Cross-record duplicate → error.
- [ ] Two canonicals → error.

> Blank path, bad format, intra-record duplicate, cross-record duplicate, and two-canonicals rules are all upstream `Hyrax::RedirectValidator` behavior, covered by Hyrax's `redirect_validator_spec.rb`.

### Resolver: 301 redirect at request time

- [ ] Registered work path → 301 with correct Location.
- [ ] Registered collection path → 301 to `/collections/<id>`.
- [ ] Path with trailing slash → same record.
- [ ] Unregistered path → 404.
- [x] Real Hyku routes take priority over catch-all — **`route_placement_spec.rb`**: confirms `/status` → `status#index`, `/catalog` → `catalog#index`, `/bookmarks` → `bookmarks#index`.

> 301 behavior, trailing-slash normalization, and 404 for unregistered paths are upstream `Hyrax::RedirectsController` behavior, covered by Hyrax's `redirects_controller_spec.rb` and `redirects_spec.rb` request spec.

### Multi-tenancy

- [ ] Per-tenant Flipflop scoping — Flipflop on for tenant A, off for tenant B.
- [ ] Cache key isolation — same path on two tenants resolves to different records.
- [x] Admin host vs tenant host — `/account` and `/proprietor` not in reserved list — **`reserved_prefixes_spec.rb`**: explicitly confirms these are excluded.

### Two-layer gating (regression checks)

- [~] Config off, Flipflop unregistered → no Redirects tab, path → 404 — **`_form_redirects_tab_spec.rb`**: confirms tab is hidden when `redirects_active?` is false. 404 behavior is upstream.
- [~] Config on, Flipflop off → Redirects tab present, path → 404 — **`_form_redirects_tab_spec.rb`**: confirms tab renders when `redirects_active?` is true. The distinction between "Flipflop off" and "Flipflop on" is upstream gating.
- [~] Config on, Flipflop on → full feature active, path → 301 — **`_form_redirects_tab_spec.rb`**: confirms tab renders. 301 behavior is upstream.

### Sync ledger and concurrency

- [ ] After save, rows exist in `hyrax_redirect_paths` with normalized paths.
- [ ] Remove entry, save → row deleted.
- [ ] Delete work → all rows removed.
- [ ] Race condition → unique index rejects second save.

> All upstream `SyncRedirectPaths` / `RemoveRedirectPaths` behavior, covered by Hyrax's `sync_redirect_paths_spec.rb` and `remove_redirect_paths_spec.rb`.

### Bulkrax / OAI / other catch-all interactions

- [~] OAI-PMH endpoints (`/sword`, `/catalog/oai`) still work — **`reserved_prefixes_spec.rb`**: confirms `/sword` is reserved. **`route_placement_spec.rb`**: confirms catch-all is after all app routes.
- [~] Bulkrax importer/exporter URLs (`/importers`, `/exporters`) load correctly — **`reserved_prefixes_spec.rb`**: confirms both are reserved.
- [~] `/single_signon` SSO flow still works — **`reserved_prefixes_spec.rb`**: confirms it's reserved. **`route_placement_spec.rb`**: confirms real routes take priority.
- [x] `/status` health-check returns its usual response — **`route_placement_spec.rb`**: confirms `/status` routes to `status#index`, not the catch-all.

---

## Summary

| Section | Total items | Fully covered | Partially/indirectly | Manual only |
|---------|-------------|---------------|----------------------|-------------|
| Pre-flight setup | 5 | 0 | 0 | 5 |
| Pass 1: default schema | 2 | 0 | 0 | 2 |
| Pass 2: flexible schema | 10 | 0 | 0 | 10 |
| Form: work redirects | 5 | 0 | 0 | 5 |
| Form: collection redirects | 3 | 1 | 2 | 0 |
| Validation rules | 10 | 2 | 2 | 6 |
| Resolver | 5 | 1 | 0 | 4 |
| Multi-tenancy | 3 | 1 | 0 | 2 |
| Two-layer gating | 3 | 0 | 3 | 0 |
| Sync ledger | 4 | 0 | 0 | 4 |
| Bulkrax/OAI/interactions | 4 | 1 | 3 | 0 |
| **Totals** | **54** | **6** | **10** | **38** |

### What these Hyku specs cover

The 4 spec files (33 examples) focus on **Hyku-specific wiring** — the code that only exists in this repo, not upstream in Hyrax:

| Spec file | Examples | What it covers |
|-----------|----------|----------------|
| `spec/requests/redirects/reserved_prefixes_spec.rb` | 16 | Hyku's 10 added prefixes, admin-host exclusions, upstream defaults preserved |
| `spec/requests/redirects/route_placement_spec.rb` | 6 | Catch-all exists, targets correct controller, is last app route, real routes take priority |
| `spec/lib/hyrax/transactions/collection_update_decorator_spec.rb` | 6 | Thumbnail step inserted correctly, upstream steps preserved, ordering |
| `spec/views/hyrax/dashboard/collections/_form_redirects_tab_spec.rb` | 5 | Tab renders when active, hidden when inactive, hidden for new collections |

### What is covered by upstream Hyrax specs (not duplicated here)

Most of the "manual only" items above are upstream Hyrax behavior already tested by Hyrax's own CI (run across 4 test apps including `allinson` for flexible mode):

- `RedirectValidator` — all validation rules (blank, format, reserved prefix matching, duplicates, canonicals)
- `RedirectsController` — 301 resolution, 404 for unregistered, trailing-slash normalization, Solr error handling
- `SyncRedirectPaths` / `RemoveRedirectPaths` — ledger sync, cleanup on delete, race condition handling
- `RedirectsTabHelper` — tab visibility logic
- `RedirectPathNormalizer` — URL-to-path normalization
- `RedirectsLookup` — uniqueness checking
- `FlexibleSchemaValidators::RedirectsValidator` — m3 profile validation matrix
- Schema attribute presence under both `HYRAX_FLEXIBLE` modes
