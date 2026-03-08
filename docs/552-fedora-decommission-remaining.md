# #552 – Fedora decommission: remaining work

**Objective:** Define and implement the steps required to safely turn off Fedora (Fcrepo) after migrating tenants to Valkyrie with Postgres backing.

**Scope:** Adapter transition · Tenant-level considerations · App startup dependencies · Deploy pipeline impact · Infrastructure removal

---

## Key questions (answered)

| Question | Answer |
|----------|--------|
| **Do we support adapter selection per tenant?** | **No.** Adapter is **global per app** (set in `config/initializers/wings.rb`). No per-tenant refactor needed for 552. |
| **Should Fedora be an option once app is Valkyrie-based?** | **No.** Goal is Fedora off; remove it as a selectable feature and from deployment. |
| **Copy `.koppie` / `.dassie` initializers and override in tenant app?** | **Not required.** Hyku uses a single `wings.rb`; Freyja is the current metadata adapter. For full Valkyrie+Postgres (no Freyja), you’d add a Postgres metadata adapter initializer (e.g. from `.koppie/1_valkyrie.rb`) and switch config; no Knapsack-style tenant override needed for 552. |
| **What still requires Fedora at runtime?** | With `DISABLE_WINGS=true` / no-Wings mode: **app code does not require Fedora** (gated in PR #2952). **Compose/infra** still define and depend on the Fcrepo service until removed. |
| **Is Fcrepo required by db-wait / Helm / Terraform / probes?** | **db-migrate-seed:** No—script is mode-aware and skips Fcrepo wait when Wings disabled. **Helm / Terraform / ArgoCD / probes:** Must be checked and updated in **infrastructure repos** (not in this app repo). |

---

## Investigation tasks

### Confirm all tenants migrated

*Coordinate with team before proceeding.*

| Task | Status | Notes |
|------|--------|--------|
| Confirm PALS fully migrated to Valkyrie | ⬜ To do | Operational check (e.g. PALS tenant). |
| Verify no UUIDs still stored only in Fedora | ⬜ To do | Spot-check migration coverage. |
| Confirm Solr reindex completed per tenant | ⬜ To do | Run/verify per-tenant reindex. |
| Confirm no Fedora writes occurring | ⬜ To do | With `DISABLE_WINGS=true`, app doesn’t route to Fedora; confirm via logs/metrics. |

---

### Adapter architecture review

| Task | Status | Notes |
|------|--------|--------|
| Identify where adapter is selected | ✅ Done | `config/initializers/wings.rb`: `Valkyrie.config.metadata_adapter = :freyja`, storage adapter, Wings prune. |
| Determine if adapter config is global | ✅ Done | Yes, global. |
| Evaluate feasibility of per-tenant adapter | ✅ Done | Possible but major refactor; not needed for 552. |
| Determine if tenant-level refactor required | ✅ Done | No; require “all tenants on Valkyrie+Postgres” then turn Fedora off globally. |

**Relevant files:** `config/initializers/wings.rb`, `config/initializers/hyrax.rb`. No separate `1_valkyrie.rb` in this repo; Freyja is the current Valkyrie metadata adapter.

---

### Remove Fedora as a feature

| Task | Status | Notes |
|------|--------|--------|
| Remove Fedora as selectable feature | 🟡 Partial | Runtime gated by `Hyrax.config.disable_wings` (PR #2952). Optional: hardcode `disable_wings = true` and remove Fedora toggles from code/locales. |
| Prevent Fedora from being provisioned for new tenants | ✅ Done | When `DISABLE_WINGS=true`, `CreateFcrepoEndpointJob` not run. Remove job/model usage after cutover. |
| Ensure startup does not assume Fedora presence | 🟡 Partial | App code: yes. **Compose:** base compose still defines `fcrepo` and `depends_on`; remove so base runs without Fedora. |

---

### Application startup dependencies

| Question | Status | Notes |
|----------|--------|--------|
| Does app fail to boot without Fedora? | ✅ No (code) | In no-Wings mode, Rails does not require Fedora. Compose still starts Fcrepo; remove from compose. |
| Does proprietor setup require Fedora? | ✅ No | Gated by `Hyrax.config.disable_wings`. |
| Are endpoints auto-created at account creation? | ✅ Gated | Skipped when `Hyrax.config.disable_wings` is true. |
| Does any initializer assume Fedora connection? | ✅ No | `wings.rb` and `db-migrate-seed.sh` are mode-aware. |

---

### Deploy & infrastructure review

| Task | Status | Notes |
|------|--------|--------|
| Is Fcrepo container deployed via Helm? | ⬜ Check | In **infra/chart repo** (not this app repo). |
| Is Fcrepo required in readiness probes? | ⬜ Check | Ensure app pods do not depend on Fcrepo. |
| Is db-wait dependent on Fedora? | ✅ No | `bin/db-migrate-seed.sh` only waits for Fcrepo when `!disable_wings && FCREPO_HOST`. |
| Remove from deploy pipeline if not required | ⬜ To do | Compose + Helm/Terraform/ArgoCD. |
| Remove from Terraform | ⬜ To do | In infra repo. |
| Remove from ArgoCD manifests | ⬜ To do | In infra repo. |

---

## Safe decommission plan (per-tenant)

Execute in this order:

1. ⬜ **Confirm tenant fully on Valkyrie** (per-tenant validation).
2. ⬜ **Remove FcrepoEndpoint record** (rake/script per tenant; e.g. `account.fcrepo_endpoint&.destroy` or nullify and then cleanup).
3. ⬜ **Remove Fedora service from environment** (compose + Helm/Terraform).
4. ⬜ **Deploy without Fedora** and verify.
5. ⬜ **Monitor errors** (no hidden Fcrepo dependencies).
6. ⬜ **Decommission storage** (infra/storage team).

---

## Code / schema work in this repo

| Task | Status | Notes |
|------|--------|--------|
| Make base compose run without Fcrepo | ⬜ To do | Remove `fcrepo` service and all `depends_on: fcrepo` from `docker-compose.yml` and `docker-compose.production.yml`. Optional: add `docker-compose.fcrepo4.yml` overlay for envs that still need it. |
| Data cleanup: remove FcrepoEndpoint usage | ⬜ To do | After all tenants validated, script or rake to delete/nullify `FcrepoEndpoint` records per tenant. |
| Migration: drop `accounts.fcrepo_endpoint_id` | ⬜ To do | After endpoints removed: migration to drop FK and index; optionally remove `FcrepoEndpoint` / `NilFcrepoEndpoint` and related code. |
| (Optional) Add Postgres Valkyrie metadata adapter | ⬜ Optional | If moving from Freyja to pure Valkyrie+Postgres: add initializer (e.g. from Hyrax `.koppie/1_valkyrie.rb`) and set `Valkyrie.config.metadata_adapter` to Postgres. |

---

## Risks

- Hidden initializer dependency (mitigated by PR #2952; final check when Fcrepo is removed from compose).
- Wings adapter still referenced in background jobs (PR #2952 prunes Wings when disabled; confirm reindex/lease/embargo jobs in no-Wings mode).
- Fedora referenced in feature flags (gates use `Hyrax.config.disable_wings`; no separate feature flags found).
- Migration edge case for UUID storage (verify no UUIDs only in Fedora before decommission).

---

## Deliverables

| Deliverable | Status |
|-------------|--------|
| Refactored adapter configuration | ✅ Runtime done (wings.rb). Optional: add Postgres metadata adapter initializer. |
| Fedora disabled in app | ✅ Gated; optional: hard-remove toggles and FcrepoEndpoint after data cleanup. |
| Fedora removed from deployment | ⬜ Pending compose + Helm/Terraform/ArgoCD cleanup. |

---

## Acceptance criteria

| Criterion | Status |
|----------|--------|
| All tenants operating on Valkyrie + Postgres | ⬜ Confirm (ops; e.g. PALS). |
| App boots without Fedora | ✅ Code path; ⬜ Compose updated so stack doesn’t require Fcrepo. |
| No Fedora containers deployed | ⬜ Remove from compose and infra (Helm/Terraform/ArgoCD). |
| No Fedora endpoints in database | ⬜ Data cleanup + migration to drop `fcrepo_endpoint_id`. |
| Infrastructure cleaned up | ⬜ Compose + Helm + Terraform + ArgoCD. |
| Verify #538 (FileSet deletion/indexing Valkyrie source of truth) resolved | ⬜ Re-test after Fedora off and migration cleanup. |

---

## Quick reference: what’s in this repo vs elsewhere

| Where | What |
|-------|------|
| **This repo (Hyku)** | `wings.rb`, account/job/controller/views gating, `db-migrate-seed.sh`, compose files, FcrepoEndpoint model and DB column. |
| **Infra / chart repos** | Helm charts, Terraform, ArgoCD manifests, K8s probes—remove Fcrepo there. |
| **Ops / team** | Per-tenant migration validation (PALS, reindex, no Fedora writes), decommission storage. |

---

*Last updated for PR #2952 (adapter-agnostic runtime).*
