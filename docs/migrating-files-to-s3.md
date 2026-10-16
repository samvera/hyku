# Migrating original files from disk to S3

Without `REPOSITORY_S3_STORAGE`, Valkyrie writes original files to `storage/files` as `disk://` identifiers, which often means a shared or network volume that costs far more per GB than object storage. The migration itself (rake tasks, background jobs, verification, quarantine and rollback) lives in Hyrax: see Hyrax's `documentation/migrating-files-to-s3.md` for the full procedure and what each step checks. This page covers what is specific to Hyku.

It needs a Hyrax release that includes the `hyrax:migrate:files_to_s3` tasks.

## 1. Turn on S3 for new files

Set `REPOSITORY_S3_STORAGE=true`, `REPOSITORY_S3_BUCKET` and `REPOSITORY_S3_REGION` (plus credentials, or ambient platform credentials; see [S3 Like Storage](configuration.md#s3-like-storage)) for every process that writes files, web and background workers, then restart them. New files get `shrine://` identifiers; existing files keep working from disk until migrated. Clear caches afterwards.

## 2. Run the Hyrax tasks for each tenant

Hyku's `tenantize:task` runs a rake task inside each tenant (search-only accounts are skipped). Limit it with `tenants`, a space-separated list of tenant hostnames; leave it out to run every tenant:

```bash
DRY_RUN=true tenants="one.example.com" bundle exec rake "tenantize:task[hyrax:migrate:files_to_s3]"
INLINE=true LIMIT=5 tenants="one.example.com" bundle exec rake "tenantize:task[hyrax:migrate:files_to_s3]"
tenants="one.example.com" bundle exec rake "tenantize:task[hyrax:migrate:files_to_s3]"
```

The same wrapper works for the other tasks (`hyrax:migrate:verify_s3_files`, `report_file_storage`, `quarantine_disk_files`, `rollback_s3_migration`, `purge_quarantine`) and takes the same environment variables. Jobs enqueued from inside a tenant run in that tenant.

Hyku scopes the migration manifest per tenant (`_migration-manifests/<tenant hostname>/<file set id>.json` in the bucket), so quarantine and rollback only touch the tenant they run in.

## 3. Verify and reclaim space

Follow the verify and reclaim steps in the Hyrax guide, again once per tenant, in a non-production environment first.
