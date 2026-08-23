# Performance Profiling

- [Quick start](#quick-start)
- [Reading the mini-profiler badge](#reading-the-mini-profiler-badge)
- [The flamegraph and the tenant-switch caveat](#the-flamegraph-and-the-tenant-switch-caveat)
- [Heap analysis](#heap-analysis)
- [Profiling something other than a page load](#profiling-something-other-than-a-page-load)
- [Comparing two implementations](#comparing-two-implementations)
- [CI regression guard](#ci-regression-guard)
- [Enabling on staging](#enabling-on-staging)

## Quick start

Run the app normally in development (`rack-mini-profiler` and `stackprof` are
in the `:development` Gemfile group, so nothing to enable). Load any page and
look for the small badge in the bottom-right corner - it shows total request
time and updates on every page load.

## Reading the mini-profiler badge

Click the badge to expand it. You'll see:
- **SQL panel** - query count and time. If this is large, it's actually a
  database problem, worth re-checking even if you've ruled out the DB elsewhere.
- **Render/total timings** - how much of the request was spent in view rendering
  vs. everything else.

## The flamegraph and the tenant-switch caveat

Click the flamegraph button in the badge to get a `stackprof`-powered
flamegraph of that exact request. Wider boxes are more time-expensive frames.

Hyku is multi-tenant (the `apartment` gem, schema-per-tenant Postgres). Every
request passes through `AccountElevator`
([lib/middleware/account_elevator.rb](../lib/middleware/account_elevator.rb))
*before* your controller/view code runs, switching the Postgres schema for the
current tenant. This shows up in the flamegraph as its own frames
(`Apartment::Tenant.switch!`, `AccountElevator#parse_tenant_name`) - that time
is real tenant-switch overhead paid on every request, not your view or
presenter code. Don't misattribute it to "Rails is slow."

## Heap analysis

Load `?pp=analyze-memory` on any authorized page for a Ruby heap snapshot
(object counts by type, largest live strings) via the stdlib `objspace`
module - useful for "why is memory growing" questions the CPU flamegraph
can't answer. This is a different feature from mini-profiler's "profile
memory" button, which needs the `memory_profiler` gem (not installed here);
we haven't added that since nothing has asked for it yet.

## Profiling something other than a page load

For a background job, rake task, or a specific presenter method you want to
isolate outside a full request/response cycle, use:

```
bundle exec rake profiling:stackprof[my_label]
```

Edit the block in [lib/tasks/profiling.rake](../lib/tasks/profiling.rake) to
call whatever code you want profiled, then run the task. It writes
`tmp/profiling/my_label.dump`, viewable with:

```
bundle exec stackprof --flamegraph tmp/profiling/my_label.dump
```

This runs as a single-threaded rake task on purpose - don't wrap a whole live
Puma server in `StackProf.run`; profiling a multi-threaded server with other
requests in flight on other threads produces a noisy, unreadable dump.

## Comparing two implementations

Once the flamegraph has pointed at a specific slow method and you have two
candidate implementations to compare, use `benchmark-ips` via the
[benchmarks/](../benchmarks/README.md) convention. This is for micro-level
"which of these two snippets is faster" questions, not whole-request profiling.

## CI regression guard

[spec/requests/work_show_query_count_spec.rb](../spec/requests/work_show_query_count_spec.rb)
asserts the work-show page issues fewer than 120 SQL queries (measured at 89
as of this writing), following the existing pattern in
[spec/features/catalog_query_count_spec.rb](../spec/features/catalog_query_count_spec.rb).
This counts queries, not wall-clock time, so it can't flake on CI runner load
- it catches N+1 regressions on a known hotspot, not general Ruby CPU slowness.

We deliberately did **not** add a CI job asserting on wall-clock timing
(`stackprof`/`benchmark-ips` output). Timings on shared CI runners are
inherently noisy (neighbor-VM contention, parallel test-runner workers), and
no amount of statistical massaging removes that when the two things being
compared don't run on identical hardware at the same moment. If a wall-clock
regression signal is ever wanted, the safer shape is a base-vs-PR
`benchmark-ips` comparison run back-to-back in the same CI job and posted as
an informational PR comment - never a pass/fail gate.

## Enabling on staging

Set `HYKU_MINI_PROFILER_ENABLED=true` (real staging deploys run
`RAILS_ENV=production`, so `Rails.env.staging?` never fires - same reasoning
as [config/initializers/bullet.rb](../config/initializers/bullet.rb)'s
`HYKU_BULLET_ENABLED`). Outside development the badge is only shown to
signed-in admins (`current_user.admin?`), via `authorization_mode:
:allow_authorized` - an anonymous visitor to a staging site with this flag on
sees nothing, unless the `show_mini_profiler_to_all_users` Flipflop feature
(toggleable per-tenant from the admin UI, no deploy needed) is turned on -
useful for comparing logged-in vs logged-out behavior on demand. The
authorization cookie is written on the *response* to an
admin's first request after enabling, so the badge itself only appears
starting on their second page load.

This intentionally does **not** rely on the gem's `:development` Gemfile
group for safety - the Docker image currently bundles every group regardless
of `RAILS_ENV`, so the env-var + admin-authorization check above is the real
gate. Production stays safe as long as `HYKU_MINI_PROFILER_ENABLED` is unset
there, exactly the same operational assumption bullet already relies on.
