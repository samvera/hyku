# frozen_string_literal: true

namespace :hyku do
  namespace :branding do
    namespace :migrate do
      desc <<~DESC
        Copy site branding images from legacy locations to the permanent branding directory.

        Site branding images (banners, logos, favicons, etc.) may still be stored at legacy
        paths (either the temporary upload staging directory or public/system). This task
        enqueues a background job per tenant that copies each image to the new location under
        HYRAX_BRANDING_PATH (default: public/branding/{tenant}).

        The job is idempotent — already-migrated images are skipped. Re-run safely after
        partial failures.

        Options:
          tenant  Optional Apartment tenant UUID. Omit to run for all tenants.

        Examples:
          bin/rails hyku:branding:migrate:copy
          bin/rails "hyku:branding:migrate:copy[my-tenant-uuid]"

        After running, verify with:
          bin/rails hyku:branding:migrate:verify

        Then remove old files with:
          bin/rails hyku:branding:migrate:cleanup
      DESC
      task :copy, [:tenant] => :environment do |_t, args|
        tenants = branding_migration_tenant_list(args[:tenant])
        tenants.each { |t| BrandingMigrationCopyJob.perform_later(tenant: t) }
        puts "Enqueued #{tenants.count} BrandingMigrationCopyJob(s)."
        puts branding_migration_monitor_hint
      end

      desc <<~DESC
        Verify site branding images exist at the new permanent branding directory (dry run).

        Checks each tenant's Site branding columns and logs whether each image is present
        at the new path or still only at a legacy location. Makes no filesystem changes.

        Run this after migrate:copy and before migrate:cleanup to confirm all copies succeeded.

        Options:
          tenant  Optional Apartment tenant UUID. Omit to run for all tenants.

        Examples:
          bin/rails hyku:branding:migrate:verify
          bin/rails "hyku:branding:migrate:verify[my-tenant-uuid]"
      DESC
      task :verify, [:tenant] => :environment do |_t, args|
        tenants = branding_migration_tenant_list(args[:tenant])
        tenants.each { |t| BrandingMigrationVerifyJob.perform_later(tenant: t) }
        puts "Enqueued #{tenants.count} BrandingMigrationVerifyJob(s)."
        puts branding_migration_monitor_hint
      end

      desc <<~DESC
        Delete legacy branding image files after confirming they exist at the new path.

        For each tenant, removes files from legacy locations (upload staging path or
        public/system) ONLY if the file already exists at the new branding_path. Files
        that have not been copied yet are skipped with a warning.

        Run rake hyku:branding:migrate:verify first to confirm all copies succeeded.

        Options:
          tenant  Optional Apartment tenant UUID. Omit to run for all tenants.

        Examples:
          bin/rails hyku:branding:migrate:cleanup
          bin/rails "hyku:branding:migrate:cleanup[my-tenant-uuid]"
      DESC
      task :cleanup, [:tenant] => :environment do |_t, args|
        tenants = branding_migration_tenant_list(args[:tenant])
        tenants.each { |t| BrandingMigrationCleanupJob.perform_later(tenant: t) }
        puts "Enqueued #{tenants.count} BrandingMigrationCleanupJob(s)."
        puts branding_migration_monitor_hint
      end
    end
  end
end

def branding_migration_tenant_list(tenant_arg)
  if tenant_arg.present?
    [tenant_arg]
  else
    Account.where(search_only: false).pluck(:tenant)
  end
end

def branding_migration_monitor_hint
  <<~HINT

    Jobs are processing in the background. Monitor progress with:
      tail -f log/#{Rails.env}.log | grep BrandingMigration

    Or check the Background job dashboard if available.
  HINT
end
