---
name: test-redirects
description: Run the Hyku redirects feature testing checklist using Playwright MCP, curl, and rails runner. Covers form UI, validation, 301 resolution, ledger sync, and route interactions.
disable-model-invocation: true
---

# Hyku Redirects Feature — Automated Testing

Run the full redirects testing checklist from [notch8/palni_palci_knapsack#649](https://github.com/notch8/palni_palci_knapsack/issues/649).

## Arguments

`$ARGUMENTS` can be:
- (empty) — run the full checklist for the current flex mode
- `flexible` — explicitly note this is the HYRAX_FLEXIBLE=true pass
- `default` — explicitly note this is the HYRAX_FLEXIBLE=false pass

## Prerequisites

Before running, confirm:
1. The app is running in Docker (`docker compose up`)
2. `HYRAX_REDIRECTS_ENABLED` is set in `docker-compose.override.yml`
3. You know the current `HYRAX_FLEXIBLE` setting
4. Basic auth credentials: `samvera` / `hyku`
5. Admin login: `admin@example.com` / `testing123`
6. Playwright MCP server is installed (`claude mcp add playwright -- npx @playwright/mcp@latest`)

## What to test

Work through these sections in order. For each test, log the result (PASS/FAIL/SKIP) and take a screenshot where relevant. Save screenshots to `spec/redirects_testing/` and write results to `spec/redirects_testing/TEST_RESULTS.md`.

### Section 0: Environment check

Use `docker compose exec web` and `rails runner` to confirm:
- What `HYRAX_FLEXIBLE` is set to (determines which pass this is)
- `Hyrax.config.redirects_enabled?` returns true
- `Flipflop.redirects?` returns true (within tenant context)
- `Hyrax.config.redirects_active?` returns true (within tenant context)
- The `hyrax_redirect_paths` table exists

If the FlipFlop is off, navigate to `/admin/features` and turn it on before proceeding.

### Section 1: Form — adding redirects to a work

Using Playwright MCP:
1. Navigate to `/dashboard/my/works`, pick an existing work, go to its edit page
2. Verify the **Aliases** tab is visible (take screenshot)
3. Click the Aliases tab, add a redirect path like `/handle/12345/678`, save
4. Reload the edit form, verify the entry persists in the Aliases tab (take screenshot)
5. Add a second entry with a full URL like `https://old.example.edu/handle/99999/abc?utm=email`, save
6. Reload and verify it was normalized to `/handle/99999/abc` (take screenshot)
7. Note the work ID for later ledger/resolver checks

### Section 2: Validation rules

Using Playwright MCP on a **different** work (to avoid conflicts with Section 1):
1. **Reserved Hyrax prefix** — try `/dashboard`, expect rejection with reserved-prefix error (screenshot)
2. **Reserved Hyku prefix** — try `/single_signon`, expect rejection (screenshot)
3. **Reserved prefix subpath** — try `/single_signon/foo`, expect rejection (screenshot)
4. **Non-reserved lookalike** — try `/single_signon_admin`, expect acceptance (screenshot)
5. **Cross-record duplicate** — try the path registered in Section 1, expect "already in use" error (screenshot)

After testing, clean up: remove any entries that were accepted on this second work.

### Section 3: Resolver — 301 redirect

Using `curl -sk -I -u samvera:hyku` against the tenant URL:
1. **Registered path** — `curl` the path from Section 1, expect HTTP 301 with correct `Location` header
2. **Trailing slash** — same path with trailing `/`, expect 301 to same record
3. **Unregistered path** — a random path like `/nonexistent/xyz`, expect 404
4. **Real route priority** — `/dashboard`, `/catalog`, `/bookmarks` should NOT be caught by the catch-all

### Section 4: Ledger sync

Using `docker compose exec web rails runner` within tenant context:
1. Query `Hyrax::RedirectPath.where(resource_id: '<work_id>')` for the Section 1 work — expect rows with normalized paths
2. Check total row count matches expected

### Section 5: Route interactions

Using `curl -sk -o /dev/null -w "%{http_code}" -u samvera:hyku` for each:
- `/status` — should NOT be 301 (expect 200 or 302)
- `/importers` — should NOT be 301
- `/exporters` — should NOT be 301
- `/single_signon` — should NOT be 301
- `/bookmarks` — should NOT be 301
- `/browse` — should NOT be 301
- `/sword` — should NOT be 301

### Section 6: Flexible-mode specific (only when HYRAX_FLEXIBLE=true)

Using `docker compose exec web rails runner`:
1. Config off + m3 profile still declares `redirects` — set `Hyrax.config.redirects_enabled = false` in runner, check if `GenericWorkResource.new.respond_to?(:redirects)` still returns true (document the caveat)

### Section 7: RSpec automated specs

Run the Hyku-specific redirects specs to make sure they still pass:
```
docker compose exec web bundle exec rspec \
  spec/requests/redirects/ \
  spec/lib/hyrax/transactions/collection_update_decorator_spec.rb \
  spec/views/hyrax/dashboard/collections/_form_redirects_tab_spec.rb \
  --format documentation
```

## Output

Write all results to `spec/redirects_testing/TEST_RESULTS.md` using this format:

```markdown
# Redirects Feature — Manual Test Results

**Date:** <today>
**Tester:** <who ran this>
**Mode:** Pass N — HYRAX_FLEXIBLE=<true|false>
**Tenant:** <tenant URL>

## Section N: <name>

| Check | Result | Notes |
|-------|--------|-------|
| ... | PASS/FAIL | ... |
```

Include screenshots in `spec/redirects_testing/` named with the section number prefix (e.g., `01_aliases_tab.png`, `02_reserved_prefix_error.png`).

## After both passes

Once you have completed both Pass 1 (HYRAX_FLEXIBLE=false) and Pass 2 (HYRAX_FLEXIBLE=true), compare the results. Flag any differences — both passes should produce identical behavior for the shared body sections. Mode-specific differences are expected only in the schema-loading path (Section 6).
