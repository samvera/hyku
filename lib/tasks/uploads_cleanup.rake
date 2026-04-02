# frozen_string_literal: true

# Scheduled via cron / Kubernetes CronJob (or similar). Uses ActiveJob only—works with Sidekiq, GoodJob,
# or any other queue adapter; no GoodJob-specific APIs.

namespace :hyku do
  desc "Enqueue per-tenant Hyrax upload staging cleanup (DELETE_INGESTED_AFTER_DAYS, DELETE_ALL_AFTER_DAYS); skips S3 tenants"
  task cleanup_uploads: :environment do
    ingested = ENV.fetch("DELETE_INGESTED_AFTER_DAYS", "180").to_i
    delete_all = ENV.fetch("DELETE_ALL_AFTER_DAYS", "730").to_i

    Account.find_each do |account|
      Apartment::Tenant.switch(account.tenant) do
        if Site.account&.s3_bucket.present?
          puts "Skipping #{account.tenant}: S3 uploads (no local staging tree)"
          next
        end

        uploads_path = Hyrax.config.upload_path.call
        uploads_path = uploads_path.to_s

        unless Dir.exist?(uploads_path)
          puts "Skipping #{account.tenant}: #{uploads_path} does not exist"
          next
        end

        puts "Enqueueing cleanup for #{account.tenant} → #{uploads_path}"

        CleanupUploadFilesJob.perform_later(
          delete_ingested_after_days: ingested,
          uploads_path: uploads_path,
          delete_all_after_days: delete_all,
          tenant: account.tenant
        )
      end
    end
  end
end
