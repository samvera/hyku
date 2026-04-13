# VPAT / ACR workbook checklist (Hyku)

Use this when moving from repository evidence to the **ITI VPAT** or **ACR** workbook your organization approved. This file does not replace legal or procurement review.

## Before you start

1. Confirm the **workbook edition** matches your procurement (e.g. WCAG 2.1 Level A & AA).
2. Gather **release metadata**: product version, commit or build ID, evaluation date, environment URL, browsers, assistive technology used for manual checks.
3. Open [`acr-evidence-template.md`](./acr-evidence-template.md) and [`manual-results-template.csv`](./manual-results-template.csv) for one evaluation cycle.

## Map traceability YAML to workbook tables

1. Open [`wcag-2.1-aa-traceability-matrix.yaml`](./wcag-2.1-aa-traceability-matrix.yaml).
2. For each **criterion** row, locate the matching row in the ITI **WCAG** table (or Section 508 / EN 301 549 tables if required).
3. Copy **`coverage`** into your notes: `automated_axe`, `semi_automated`, or `manual` informs how much weight to put on RSpec vs human testing.
4. Copy **`specs`** file paths into internal evidence links; paste **`evidence`** text into your draft or shorten for the workbook “Remarks” column.
5. For **`notes`** on a criterion, ensure any open exceptions are reflected in workbook status (**Partially Supports** / **Does Not Support**) with ticket IDs.

## Attach automated evidence

1. **axe RSpec**: reference a green CI run of `build-test-lint` (see `meta.ci` in the YAML) or attach `tmp/a11y/` from `A11Y_ARTIFACTS=1` runs.
2. **Playwright + axe** (Docker / CI): attach `tmp/playwright-a11y/` (screenshots, `*.violations.aa.json`, optional `*.violations.aaa.json`). **A/AA** results gate CI; **AAA** files are supplementary (see [README § Playwright](./README.md#playwright-route-audit-docker) and `meta.playwright_route_audit` in the traceability YAML).
3. **Pa11y** (if used): attach JSON/HTML reports and the URL list or [`pa11yci.sample.json`](./pa11yci.sample.json) variant you ran.

## Complete manual rows

1. Every criterion marked **`manual`** or **`semi_automated`** in the YAML still needs human validation notes (keyboard, zoom, screen reader, etc.) per [README § Manual release playbook](./README.md#manual-release-playbook).
2. Record results in `manual-results-template.csv` or the ACR template table.

## Sign-off

- [ ] All **automated_axe** criteria have a spec path + run reference or artifact.
- [ ] All **manual** criteria have dated tester notes.
- [ ] Third-party components (UV, pdf.js, etc.) have agreed **scope** language per README.
- [ ] Procurement / legal reviewer named and date recorded.
