# Migrating original files from disk (EFS) to S3

Without `REPOSITORY_S3_STORAGE`, Valkyrie writes original files to `storage/files` as `disk://` identifiers. On Kubernetes that directory is usually a shared volume such as EFS, which is far more expensive per GB than S3. This guide moves new and existing originals to S3.

Only originals move. Derivatives (`HYRAX_DERIVATIVES_PATH`), uploads, branding and imports stay on the shared volume (see [S3 Like Storage](configuration.md#s3-like-storage)).

## 1. Create the bucket

One private, encrypted bucket per tenant group/client, in the same region as the cluster (the app streams files through the pods, so cross-region adds latency and transfer cost). Enable versioning and block public access.

## 2. Give the app access

Either grant the pods' IAM role (IRSA or node role) read/write on the bucket and leave the key variables unset (the AWS SDK default credential chain is used), or set `REPOSITORY_S3_ACCESS_KEY` / `REPOSITORY_S3_SECRET_KEY`.

## 3. Turn on S3 for new files

Set on web, worker and auxiliary-worker deployments, then deploy:

```yaml
- name: REPOSITORY_S3_STORAGE
  value: "true"
- name: REPOSITORY_S3_BUCKET
  value: <bucket>
- name: REPOSITORY_S3_REGION
  value: <region>
```

New files now get `shrine://` identifiers. Existing files keep working from disk until migrated. Clear caches (Rails cache, IIIF/derivative caches) after the deploy.

## 4. Migrate existing files

`hyku:migrate_files_to_s3` enqueues one background job per file set (`MigrateTenantFilesToS3Job` lists a tenant's disk files, `MigrateFileSetToS3Job` moves each one), so speed scales with your job workers. Each job uploads the file, reads it back from S3 and compares its SHA-256 with the disk file, and only then switches the identifier; on a mismatch the upload is removed and the file stays on disk. Before uploading, the disk file is also checked against the checksum recorded at characterization (MD5 or SHA-1); a mismatch is reported as `suspect` and the file is not migrated. Transient errors retry. The disk copy is never touched, and the task is re-runnable (migrated files are skipped).

Start with a dry run, which runs inline and prints what it would do (it reads every file to check checksums, so it takes a while on large tenants):

```bash
DRY_RUN=true TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
```

Then a small real batch, run inline so you can read the output, followed by the full run, which enqueues jobs:

```bash
INLINE=true LIMIT=5 TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
```

Omit `TENANT` to run every tenant (the cross-tenant `search` account is skipped, and a failing tenant is reported while the rest continue). Set `S3_MIGRATION_QUEUE` to run the jobs on a dedicated queue (your workers must be listening to it) so ingest and derivative jobs are not starved. Per-file results are logged as `[S3Migration] <file set id> <status>`. Every migrated file also gets a manifest object (see step 6). Watch the shared volume's throughput while it runs: the live site reads from it too, so start with few workers.

## 5. Verify

- Audit what is in S3 (read-only; checks existence, recorded size and stored MD5): `TENANT=<cname> bundle exec rake hyku:verify_files_in_s3`. Expect `Problems: 0`.
- A newly created work's original has a `shrine://` identifier.
- Old and new works still display their files (viewer/IIIF, downloads) after clearing caches.
- Thumbnails are unaffected (they are derivatives).
- A re-run reports `Migrated: 0`.

## 6. Reclaim EFS space

Every migrated file is recorded in a manifest object in the bucket (`_migration-manifests/<file set id>.json`: tenant, file set and file IDs, old disk id, new S3 id, size, SHA-256). Deletion is manifest-driven, never `rm -rf storage/files`.

1. Take an EFS snapshot / AWS Backup recovery point. Keep bucket versioning on.
2. `bundle exec rake hyku:report_file_storage` lists what is still on disk by file use and scheme. The migration only moves originals; extracted text, other file versions etc. may still be `disk://` and are not covered by the manifest.
3. Dry-run, then apply: `bundle exec rake hyku:quarantine_migrated_disk_files` (add `APPLY=true`). For each file it re-checks that the database still points at the S3 id and that the S3 object matches the manifest size and SHA-256, then moves the disk copy to `<storage>/.quarantine` (same volume, so it is a rename).
4. Soak (at least a week or two, through a backup cycle), re-checking the site. To undo, `bundle exec rake hyku:rollback_migrated_files` (dry-run by default, `APPLY=true`) restores the disk copy and the original identifier from the manifest.
5. Permanently delete: `bundle exec rake hyku:purge_quarantine` (dry-run by default; `APPLY=true`, `MIN_AGE_DAYS=14`).

Do staging first and production after, checking again between each. EFS charges by stored bytes, so the saving only appears after step 5. Derivatives often remain on the volume; size them separately (`du -sh $HYRAX_DERIVATIVES_PATH`). EFS lifecycle management (transition to Infrequent Access) lowers the cost of untouched files in the meantime without deleting anything.
