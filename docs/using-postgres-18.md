# Migrating from Postgres 11 to Postgres 18

**Postgres 11 is still the default** in all three compose files until a separate,
explicit major-version-bump release switches it.

## Do you need to migrate your data?

Yes - unlike the Solr 9 upgrade, there's no free lunch here. Postgres doesn't read a
previous major version's on-disk files at all: pointing Postgres 18 at a Postgres
11-written data directory fails outright (`FATAL: database files are incompatible
with server`, or an explicit refusal in the container logs telling you to use
`pg_upgrade`). Postgres major-version upgrades always require an explicit migration
step - `pg_dump`/`pg_restore`, or `pg_upgrade` - there's no in-place schema tweak that
avoids it.

The Postgres 18 image also expects a different volume mount than 11 did: `/var/lib/postgresql`
instead of `/var/lib/postgresql/data` (its own data subdirectory lives underneath that,
following [upstream's own guidance](https://github.com/docker-library/postgres/issues/37)
for a layout that works with `pg_upgrade --link`). If a volume is mounted at
`/var/lib/postgresql/data` at all - even empty, even alongside a correct mount
elsewhere - Postgres 18's entrypoint detects it and refuses to start. This ruled out
a `docker-compose.override.yml` file for this one: merging a second volume mount in
via Compose doesn't remove the first, so the old, empty mount would still be present
and Postgres 18 would refuse to boot. `!override`/`!reset` YAML tags could force a
clean replace, but that Compose Spec feature needs Compose >= ~2.24, the same version
floor this repo has already been burned by once (see `env-file-lint` in
`build-test-lint.yaml`) - not something to depend on silently failing into a confusing
error for anyone on an older Compose or going through `stack_car`'s `sc` wrapper.

Instead, `POSTGRES_VERSION` and `POSTGRES_DATA_DIR` are plain environment variables on
the `db` service in all three compose files, the same pattern already used for Solr's
`SOLR_VERSION`. No file merging, so no stray mount is possible either way.

## In development and test

Since there's no in-place upgrade for real data, start fresh: tear down the `db`
volume, then bring it back up with both variables set.

```bash
docker compose down -v  # or just: docker volume rm hyku_db
POSTGRES_VERSION=18 POSTGRES_DATA_DIR=/var/lib/postgresql docker compose up
```

Unset both (or just omit them) to go back to the Postgres 11 default - against a
*different* fresh volume, for the same reason.

### Combining with Solr 9

Solr 9's opt-in ([using-solr-9.md](using-solr-9.md)) uses a `docker-compose.override.yml`
file; Postgres 18's opt-in here is environment variables. They touch different
services and different mechanisms, so combining them is just doing both at once:

```bash
cp docker-compose.override-solr-9.yml docker-compose.override.yml
POSTGRES_VERSION=18 POSTGRES_DATA_DIR=/var/lib/postgresql docker compose up
```

## In production

This is a real migration, not a config flip - plan it like one. Postgres's own
[major version upgrade documentation](https://www.postgresql.org/docs/current/upgrading.html)
covers `pg_dump`/`pg_restore` and `pg_upgrade`; decide which fits your downtime
tolerance and data size before touching `docker-compose.production.yml`. Once you've
migrated the data itself (to wherever the new Postgres 18 process will read it from),
set `POSTGRES_VERSION=18` and `POSTGRES_DATA_DIR=/var/lib/postgresql` for that
deployment the same way as above.
