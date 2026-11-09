# Migrating from Postgres 11 to Postgres 18

Postgres 11 stays the default in all three compose files until a dedicated
major-version-bump release switches it.

## Data migration is required

Postgres doesn't read a previous major version's data files - pointing 18 at an
11-written data directory fails outright (`FATAL: database files are incompatible
with server`; the container logs also point at `pg_upgrade`). Use `pg_dump`/`pg_restore`
or `pg_upgrade` to move data across the version bump; there's no config-only path.

Postgres 18 also expects its volume mounted at `/var/lib/postgresql` rather than
`/var/lib/postgresql/data`. `POSTGRES_VERSION` and `POSTGRES_DATA_DIR` are plain
environment variables on the `db` service in all three compose files (same pattern as
Solr's `SOLR_VERSION`) rather than an override file, since Postgres 18's entrypoint
refuses to start if a volume is mounted at the old path at all, even empty, and Compose
merges override files' volume lists instead of replacing them.

## In development and test

Start fresh - there's no in-place upgrade path for existing local data:

```bash
docker compose down -v  # or: docker volume rm hyku_db
POSTGRES_VERSION=18 POSTGRES_DATA_DIR=/var/lib/postgresql docker compose up
```

Omit both variables to go back to Postgres 11, against a separate fresh volume.

## In production

Plan this as a real migration. See Postgres's own [upgrade documentation](https://www.postgresql.org/docs/current/upgrading.html)
for `pg_dump`/`pg_restore` vs. `pg_upgrade` tradeoffs. Once data is migrated, set
`POSTGRES_VERSION=18` and `POSTGRES_DATA_DIR=/var/lib/postgresql` for that deployment.
