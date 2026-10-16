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

The task is re-runnable (migrated files are skipped) and never deletes the disk copy. Each upload is read back from S3 and its SHA-256 compared with the disk file before the identifier is switched; on a mismatch the upload is removed and the file stays on disk. Before uploading, the disk file is also checked against the checksum recorded at characterization (MD5 or SHA-1); a mismatch is reported as `SUSPECT` and the file is not migrated, so corruption already on disk is caught up front. Dry runs report suspects too, but hash every file. Run it from a Rails console/shell on a pod with the volume mounted:

```bash
DRY_RUN=true TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
LIMIT=5 TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
```

Omit `TENANT` to run every tenant. For a large tenant, run several processes at once with `SHARD=<i>/<n>` (zero-based, e.g. `SHARD=0/4` through `SHARD=3/4`), each in its own pod or Job rather than an interactive console. Shards never overlap, and a file already migrated elsewhere is skipped (and its extra upload removed) just before the identifier is saved. Sum the summary lines at the end. Watch the shared volume's throughput while running: the live site reads from it too, so start with two shards. Every shard still lists all file sets for the tenant; only the per-file work is split. Errors (for example a file missing on disk) are printed per file and counted at the end; investigate them before cleaning up. To run in the background across tenants, see [Run rake task on all or selected tenants](wiki/Run-rake-task-on-all-or-selected-tenants.md).

## 5. Verify

- Audit what is in S3 (read-only; checks existence, recorded size and stored MD5): `TENANT=<cname> bundle exec rake hyku:verify_files_in_s3`. Expect `Problems: 0`.
- A newly created work's original has a `shrine://` identifier.
- Old and new works still display their files (viewer/IIIF, downloads) after clearing caches.
- Thumbnails are unaffected (they are derivatives).
- A re-run reports `Migrated: 0`.

## 6. Reclaim EFS space

Every migrated file is recorded in a manifest in the bucket (`_migration-manifests/<run id>/*.jsonl`: tenant, file set and file IDs, old disk id, new S3 id, size, SHA-256) and printed as `MANIFEST` lines. Deletion is manifest-driven, never `rm -rf storage/files`.

1. Take an EFS snapshot / AWS Backup recovery point. Keep bucket versioning on.
2. `bundle exec rake hyku:report_file_storage` lists what is still on disk by file use and scheme. The migration only moves originals; extracted text, other file versions etc. may still be `disk://` and are not covered by the manifest.
3. Dry-run, then apply: `bundle exec rake hyku:quarantine_migrated_disk_files` (add `APPLY=true`; `MANIFEST_RUN=<run id>` to limit). For each file it re-checks that the database still points at the S3 id and that the S3 object matches the manifest size and SHA-256, then moves the disk copy to `<storage>/.quarantine` (same volume, so it is a rename).
4. Soak (at least a week or two, through a backup cycle), re-checking the site. To undo, `bundle exec rake hyku:rollback_migrated_files` (dry-run by default, `APPLY=true`) restores the disk copy and the original identifier from the manifest.
5. Permanently delete: `bundle exec rake hyku:purge_quarantine` (dry-run by default; `APPLY=true`, `MIN_AGE_DAYS=14`).

Do staging first and production after, checking again between each. EFS charges by stored bytes, so the saving only appears after step 5. Derivatives often remain on the volume; size them separately (`du -sh $HYRAX_DERIVATIVES_PATH`). EFS lifecycle management (transition to Infrequent Access) lowers the cost of untouched files in the meantime without deleting anything.
