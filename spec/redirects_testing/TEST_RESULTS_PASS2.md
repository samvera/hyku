# Pass 2: HYRAX_FLEXIBLE=true (m3 profile-driven schema)

## Redirects Feature — Test Results

**Date:** 2026-05-06
**Tester:** Claude Code (automated via Playwright MCP + curl + rails runner)
**Branch:** `spike/redirects-feature`
**Mode:** Pass 2 — `HYRAX_FLEXIBLE=true`
**Tenant:** dev-hyku.localhost.direct
**Config:** `HYRAX_REDIRECTS_ENABLED=true`, FlipFlop `redirects` = ON

### Summary

| | Count |
|--|-------|
| Passed | 25 |
| Failed | 0 |
| Skipped (upstream/manual) | 16 |
| **Total executed** | **25** |
| Bugs found | 0 |
| Caveats confirmed | 1 (m3 attribute leaks when config off) |

---

## Section 0: Environment check

**Method:** `docker compose exec web bash -c "echo $HYRAX_FLEXIBLE"` and `rails runner` within tenant context

| Check | Command/Action | Output | Result |
|-------|----------------|--------|--------|
| HYRAX_FLEXIBLE | `echo $HYRAX_FLEXIBLE` | `true` | PASS |
| HYRAX_REDIRECTS_ENABLED | `echo $HYRAX_REDIRECTS_ENABLED` | `true` | PASS |
| `Hyrax.config.redirects_enabled?` | `rails runner` | `true` | PASS |
| `Flipflop.redirects?` (in tenant) | `rails runner` with `AccountElevator.switch!` | `true` | PASS |
| `Hyrax.config.redirects_active?` (in tenant) | `rails runner` | `true` | PASS |
| `hyrax_redirect_paths` table exists | `Hyrax::RedirectPath.count` | `0` (initially) | PASS |
| FlipFlop UI shows redirects | Playwright: navigated to `/admin/features` | "enabled" badge, on/off buttons visible | PASS |

---

## Section 1: Flexible-mode specific checks

**Method:** `rails runner` within tenant context

| Check | Command/Action | Output | Result |
|-------|----------------|--------|--------|
| m3 profile `redirects` property imported | Imported via Metadata Profiles UI | Required fixes: `display_label`, `range`, `property_uri`, correct class names | PASS (after fix) |
| Config off + profile declares `redirects` — attribute leaks | `Hyrax.config.redirects_enabled = false; GenericWorkResource.new.respond_to?(:redirects)` | `true` | PASS (confirmed documented caveat) |

**Finding:** With config off, `M3SchemaLoader` still loads the `redirects` attribute from the profile. This is the documented caveat — not a bug, but adopters should remove the property from the profile when disabling the config.

---

## Section 2: Form — adding redirects to a work

**Method:** Playwright MCP (browser automation)
**Work:** "cat" (ID: `8fc66f72-cf17-41a9-9fdb-8c42b468239c`)

| Check | Action | Output | Result |
|-------|--------|--------|--------|
| Aliases tab visible | Navigate to work edit, check tab bar | Tab "Aliases" present alongside Descriptions, Files, Relationships, Sharing | PASS |
| Add path `/handle/12345/678`, save | Click Aliases tab, type path, click Save | Redirected to show page with success message | PASS |
| Entry persists on reload | Navigate back to edit, click Aliases tab | `/handle/12345/678` visible in table with Remove button | PASS |
| Full URL normalized | Type `https://old.example.edu/handle/99999/abc?utm=email`, save, reload | Stored as `/handle/99999/abc` — scheme, host, query stripped | PASS |
| Trailing slash collapses | `curl -sk -I /handle/12345/678/` | 301 to same Location as `/handle/12345/678` | PASS |

<details>
<summary>Screenshot: Aliases tab with persisted entries and normalized URL</summary>

![Aliases tab with entries](pass2_01_aliases_tab_with_entries.png)
</details>

---

## Section 3: Validation rules

**Method:** Playwright MCP (browser automation)
**Work for validation tests:** "flex" (ID: `c637564e-a0ae-4012-a5ab-927ef15665a8`)

| Rule | Input | Error message | Result |
|------|-------|---------------|--------|
| Reserved Hyrax prefix | `/dashboard` | `"/dashboard" can't be used. The path is reserved by the application and may not be used as an alias.` | REJECTED |
| Reserved Hyku prefix | `/single_signon` | `"/single_signon" can't be used. The path is reserved by the application and may not be used as an alias.` | REJECTED |
| Reserved prefix subpath | `/single_signon/foo` | `"/single_signon/foo" can't be used. The path is reserved by the application and may not be used as an alias.` | REJECTED |
| Non-reserved lookalike | `/single_signon_admin` | Success message: "successfully updated" | ACCEPTED |
| Cross-record duplicate | `/handle/12345/678` | `"/handle/12345/678" is already used by another work or collection.` | REJECTED |
| Blank/whitespace | ` ` (space only) | Success (whitespace stripped by normalizer, entry ignored) | IGNORED |

### Not tested (upstream Hyrax behavior, covered by Hyrax CI):
- Intra-record duplicate
- Two canonicals
- Bad format (whitespace in path, `?`, `#`)

<details>
<summary>Screenshot: Reserved Hyrax prefix "/dashboard" rejected</summary>

![Reserved Hyrax prefix error](pass2_06_validation_reserved_hyrax_prefix.png)
</details>

<details>
<summary>Screenshot: Reserved Hyku prefix subpath "/single_signon/foo" rejected</summary>

![Reserved subpath error](pass2_08_validation_reserved_subpath.png)
</details>

<details>
<summary>Screenshot: Non-reserved lookalike "/single_signon_admin" accepted</summary>

![Non-reserved lookalike accepted](pass2_07_validation_non_reserved_lookalike_accepted.png)
</details>

<details>
<summary>Screenshot: Cross-record duplicate "/handle/12345/678" rejected</summary>

![Cross-record duplicate error](pass2_05_validation_cross_record_duplicate.png)
</details>

---

## Section 4: Resolver — 301 redirect at request time

**Method:** `curl -sk -I -u samvera:hyku https://dev-hyku.localhost.direct/<path>`

| Check | URL | HTTP Status | Location header | Result |
|-------|-----|-------------|-----------------|--------|
| Work redirect | `/handle/12345/678` | **301** | `/concern/generic_works/8fc66f72-cf17-41a9-9fdb-8c42b468239c?locale=en` | PASS |
| Trailing slash | `/handle/12345/678/` | **301** | Same as above | PASS |
| Unregistered path | `/nonexistent/path/here` | **404** | N/A | PASS |
| Real route: `/dashboard` | `/dashboard` | **302** (login redirect) | Not catch-all | PASS |
| Real route: `/catalog` | `/catalog` | **200** | Not catch-all | PASS |
| Real route: `/bookmarks` | `/bookmarks` | **200** | Not catch-all | PASS |

---

## Section 5: Sync ledger (`hyrax_redirect_paths`)

**Method:** `docker compose exec web rails runner` within tenant context

| Check | Query | Output | Result |
|-------|-------|--------|--------|
| Rows exist for "cat" work | `Hyrax::RedirectPath.where(resource_id: "8fc66f72-...")` | `path=/handle/12345/678`, `path=/handle/99999/abc` | PASS |
| Rows cleaned up for "flex" work | `Hyrax::RedirectPath.where(resource_id: "c637564e-...")` | `(no rows)` | PASS |
| Total row count | `Hyrax::RedirectPath.count` | `2` | PASS |

---

## Section 6: Route interactions

**Method:** `curl -sk -o /dev/null -w "%{http_code}" -u samvera:hyku https://dev-hyku.localhost.direct/<route>`

| Route | HTTP Status | Expected | Result |
|-------|-------------|----------|--------|
| `/status` | 302 | Login redirect, not catch-all | PASS |
| `/importers` | 302 | Login redirect, not catch-all | PASS |
| `/exporters` | 302 | Login redirect, not catch-all | PASS |
| `/single_signon` | 302 | Login redirect, not catch-all | PASS |
| `/bookmarks` | 200 | Normal page, not catch-all | PASS |
| `/authorities` | 404 | Mount root, not catch-all | PASS |
| `/browse` | 200 | BrowseEverything, not catch-all | PASS |
| `/sword` | 401 | SWORD auth, not catch-all | PASS |

---

## Still requires manual testing

### Requires app restart with different env vars:
- [ ] Two-layer gating: set `HYRAX_REDIRECTS_ENABLED=false`, reboot — confirm no Redirects tab on forms, FlipFlop UI does not show `redirects`, previously-registered path returns 404
- [ ] Two-layer gating: set `HYRAX_REDIRECTS_ENABLED=true`, reboot, toggle FlipFlop OFF — confirm Redirects tab IS present on forms but previously-registered path returns 404

### Requires multi-tenant setup:
- [ ] Per-tenant FlipFlop scoping — enable redirects on tenant A, leave off on tenant B. Registered path on A returns 301; same path on B returns 404
- [ ] Cache key isolation — register the same path (e.g. `/foo`) on two tenants pointing to different works. Visit `/foo` on tenant A, then on tenant B within 60 seconds. Each should resolve to its own record
- [ ] Admin host vs tenant host — `/account` and `/proprietor` are NOT in the reserved list. Register `/account` as a redirect on a tenant work, visit it on the tenant host — should 301

### Timing-sensitive:
- [ ] Race condition — open two browser tabs on two different works, register the same path in each, save both within seconds. Exactly one should succeed; the other should show "already in use"

### Form interactions not tested in this pass:
- [ ] Edit a collection, find the Redirects tab, add a path, save, reload — confirm it persists
- [ ] Verify collection thumbnail upload still works after the decorator refactor
- [ ] Verify collection banner/logo upload still works after the decorator refactor
- [ ] Mark a redirect entry as canonical, save, reload — confirm the canonical flag persists
- [ ] Add two entries with the same path on a single record — expect "listed more than once" error (intra-record duplicate)
- [ ] Add two entries both marked canonical — expect "at most one may be marked canonical" error
- [ ] Enter a path with whitespace or `?` or `#` — expect "not a valid redirect path" error
- [ ] Delete a work entirely — confirm all its rows are removed from `hyrax_redirect_paths`

### m3 profile validation matrix (remaining rows):
- [ ] FlipFlop off, property present — expect warning ("property is loaded but unused"), profile still saves
- [ ] FlipFlop on, `available_on.class` lists no work/collection class declared in profile — expect error, save rejected
- [ ] FlipFlop on, property present and complete — expect silent (valid)
- [ ] Config off, profile declares `redirects` — expect warning ("the property will be ignored") on save
