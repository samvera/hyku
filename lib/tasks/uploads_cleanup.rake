# frozen_string_literal: true

# Scheduled via cron / Kubernetes CronJob (or similar), or in-app by UploadsCleanupJob. Uses ActiveJob only—works
# with Sidekiq, GoodJob, or any other queue adapter; no GoodJob-specific APIs.

namespace :hyku do
  desc <<~DESC
    Enqueue per-tenant Hyrax upload staging cleanup.

    Always checks the local filesystem path for every tenant—including tenants that have
    since switched to S3—so that staging files from before an S3 migration are not skipped.

    Options (all via environment variables):

      DELETE_INGESTED_AFTER_DAYS    Delete staging files whose Hyrax::UploadedFile record shows
                                    they have been ingested, if older than N days. (default: 180)

      DELETE_ALL_AFTER_DAYS         Delete all remaining staging files (including orphans) older
                                    than N days. (default: 730)

      EXTRA_UPLOAD_PATHS            Comma-separated list of additional upload base directories to
                                    scan. Useful when HYRAX_UPLOAD_PATH has changed and old files
                                    remain at the former location.

      INCLUDE_ORPHANED_TENANT_DIRS  Set to "true" to also clean UUID subdirectories in
                                    EXTRA_UPLOAD_PATHS that do not match any active tenant (e.g.
                                    deleted tenants). Files older than DELETE_ALL_AFTER_DAYS are
                                    removed. (default: false)

      DRY_RUN                       Set to "true" to log the files that would be deleted without
                                    deleting anything. (default: false)

    The same cleanup runs daily as UploadsCleanupJob when HYKU_SCHEDULE_UPLOADS_CLEANUP is on.

    Example – one-time cleanup after an HYRAX_UPLOAD_PATH migration:

      DELETE_ALL_AFTER_DAYS=60 \\
      EXTRA_UPLOAD_PATHS=/old/samvera/uploads \\
      INCLUDE_ORPHANED_TENANT_DIRS=true \\
      bin/rails hyku:cleanup_uploads
  DESC
  task cleanup_uploads: :environment do
    UploadsCleanupService.new(**UploadsCleanupService.options_from_env).run
  end
end
