# ACR evidence template — Hyku

Use one copy of this file per evaluated release, deployment, or procurement response.

## Release cadence (recommended)

- **Major / minor Hyku release**: complete this template, run `bin/rspec-a11y` (or full CI), optional Pa11y against staging, and execute the [manual release playbook](./README.md#manual-release-playbook) before publishing VPAT/ACR updates.
- **Patch or theme-only change**: at minimum run `bin/rspec-a11y` when public CSS or shared templates change; add manual spot checks if navigation or forms changed.

## Release metadata

- Product:
- Version / tag:
- Commit / build:
- Environment URL:
- Evaluation date:
- Evaluator(s):
- Browser(s):
- OS:
- Assistive technology:
- Scope notes:
- Third-party components in scope:

## Automated testing summary

### axe-core RSpec

- Command:
- Critical paths covered:
- Artifacts location:
- Result summary:
- Known exclusions:
- Follow-up tickets:

### Pa11y CI (optional)

- Command:
- URL list / config:
- Artifacts location:
- Result summary:
- Follow-up tickets:

## Manual validation summary

| Area | URLs / flows tested | Result | Notes |
|------|----------------------|--------|-------|
| Keyboard |  |  |  |
| Zoom / reflow |  |  |  |
| Text spacing |  |  |  |
| Forms / errors |  |  |  |
| Media / timing |  |  |  |
| Third-party viewers |  |  |  |
| Screen reader smoke |  |  |  |
| Hover / focus content |  |  |  |

## Criterion-level notes for VPAT drafting

| WCAG | Status | Evidence summary | Notes / exceptions / ticket |
|------|--------|------------------|-----------------------------|
| 1.1.1 |  |  |  |
| 1.3.1 |  |  |  |
| 1.4.3 |  |  |  |
| 2.1.1 |  |  |  |
| 2.1.2 |  |  |  |
| 2.4.7 |  |  |  |
| 3.3.1 |  |  |  |
| 3.3.2 |  |  |  |
| 4.1.2 |  |  |  |
| 4.1.3 |  |  |  |

## Final drafting notes

- Criteria marked Not Applicable:
- Criteria marked Partially Supports:
- Criteria marked Does Not Support:
- Open remediation tickets:
- Procurement/legal reviewer:
- Date ready for VPAT workbook paste:
