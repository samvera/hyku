# frozen_string_literal: true

# Deletes legacy branding image directories for a single tenant ONLY after confirming that
# the original style file exists at the new permanent branding_path.
#
# Idempotent: if legacy files are already gone, steps are silently skipped.
# Safe to re-run — never deletes legacy files unless the new-path original is confirmed present.
#
# Run rake hyku:branding:migrate:verify first to confirm all copies succeeded before
# running this task.
#
# Enqueued by: rake hyku:branding:migrate:cleanup[tenant]
class BrandingMigrationCleanupJob < ApplicationJob
  include BrandingMigrationPaths
  non_tenant_job

  def perform(tenant:)
    Apartment::Tenant.switch(tenant) do
      site = Site.instance
      logger.info("BrandingMigrationCleanupJob starting for tenant #{tenant}")
      deleted = 0
      skipped = 0

      BRANDING_COLUMNS.each do |col|
        dest = new_branding_dir(site, col)
        next logger.info("#{col}: no stored value, skipping") unless dest

        original = dest.join('original', site.send(col).identifier)
        unless File.exist?(original)
          logger.warn("#{col}: original not at new path #{original} — skipping legacy deletion to avoid data loss")
          skipped += 1
          next
        end

        legacy_dirs(site, col).each do |legacy_dir|
          next unless Dir.exist?(legacy_dir)

          count = Dir.glob("#{legacy_dir}/**/*").count { |f| File.file?(f) }
          FileUtils.rm_rf(legacy_dir)
          logger.info("#{col}: removed legacy directory #{legacy_dir} (#{count} file(s))")
          deleted += count
        end
      end

      logger.info("BrandingMigrationCleanupJob complete for tenant #{tenant}: #{deleted} file(s) deleted, #{skipped} column(s) skipped (new path missing)")
    end
  end
end
