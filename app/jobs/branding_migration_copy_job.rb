# frozen_string_literal: true

# Copies site branding images (banner, logo, favicon, etc.) from their legacy filesystem
# locations to the new permanent branding_path for a single tenant.
#
# All style variants (original, medium, thumb, favicon sizes) are copied. Files stored
# without a style subdirectory (older format) are placed under original/.
#
# Idempotent: skips files that already exist at the destination. Safe to re-run.
#
# Enqueued by: rake hyku:branding:migrate:copy[tenant]
class BrandingMigrationCopyJob < ApplicationJob
  include BrandingMigrationPaths
  non_tenant_job

  def perform(tenant:)
    Apartment::Tenant.switch(tenant) do
      site = Site.instance
      logger.info("BrandingMigrationCopyJob starting for tenant #{tenant}")
      copied = 0
      skipped = 0

      BRANDING_COLUMNS.each do |col|
        dest = new_branding_dir(site, col)
        next logger.info("#{col}: no stored value, skipping") unless dest

        src = legacy_dirs(site, col).find { |d| Dir.exist?(d) }
        unless src
          logger.warn("#{col}: no legacy directory found, skipping")
          next
        end

        before = count_files(dest)
        copy_branding_dir(src, dest)
        after = count_files(dest)
        delta = after - before

        if delta.zero?
          logger.info("#{col}: all files already present at #{dest}, skipping")
          skipped += 1
        else
          logger.info("#{col}: copied #{delta} file(s) from #{src} → #{dest}")
          copied += delta
        end
      end

      logger.info("BrandingMigrationCopyJob complete for tenant #{tenant}: #{copied} copied, #{skipped} column(s) already migrated")
    end
  end

  private

  def count_files(dir)
    return 0 unless dir.exist?

    Dir.glob("#{dir}/**/*").count { |f| File.file?(f) }
  end
end
