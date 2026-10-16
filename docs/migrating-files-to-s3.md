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

The task is re-runnable (migrated files are skipped) and never deletes the disk copy. Each upload is read back from S3 and its SHA-256 compared with the disk file before the identifier is switched; on a mismatch the upload is removed and the file stays on disk. Run it from a Rails console/shell on a pod with the volume mounted:

```bash
DRY_RUN=true TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
LIMIT=5 TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
TENANT=<cname> bundle exec rake hyku:migrate_files_to_s3
```

Omit `TENANT` to run every tenant. Errors (for example a file missing on disk) are printed per file and counted at the end; investigate them before cleaning up. To run in the background across tenants, see [Run rake task on all or selected tenants](wiki/Run-rake-task-on-all-or-selected-tenants.md).

## 5. Verify

- Audit what is in S3 (read-only; checks existence, recorded size and stored MD5): `TENANT=<cname> bundle exec rake hyku:verify_files_in_s3`. Expect `Problems: 0`.
- A newly created work's original has a `shrine://` identifier.
- Old and new works still display their files (viewer/IIIF, downloads) after clearing caches.
- Thumbnails are unaffected (they are derivatives).
- A re-run reports `Migrated: 0`.

## 6. Reclaim EFS space

Only after verifying, and ideally after a snapshot/backup, delete the migrated files from `storage/files`. Do staging first and production after, checking again between each. EFS charges by stored bytes, so the saving only appears once the data is deleted. Derivatives often remain on the volume; size them separately (`du -sh $HYRAX_DERIVATIVES_PATH`) before expecting the volume to shrink to near zero.
