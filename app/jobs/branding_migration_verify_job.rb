# frozen_string_literal: true

# Verifies that site branding images exist at the new permanent branding_path for a single tenant.
# Checks that the original style file is present for each column (the canonical indicator of a
# successful migration). Read-only — makes no filesystem changes.
#
# Logs INFO for each column found at the new path and WARN for each that is still missing.
# Run this between copy and cleanup to confirm the copy succeeded before deleting legacy files.
#
# Enqueued by: rake hyku:branding:migrate:verify[tenant]
class BrandingMigrationVerifyJob < ApplicationJob
  include BrandingMigrationPaths
  non_tenant_job

  def perform(tenant:)
    Apartment::Tenant.switch(tenant) do
      site = Site.instance
      logger.info("BrandingMigrationVerifyJob starting for tenant #{tenant}")
      ok = 0
      missing = 0

      BRANDING_COLUMNS.each do |col|
        dest = new_branding_dir(site, col)
        next logger.info("#{col}: no stored value") unless dest

        original = dest.join('original', site.send(col).identifier)
        if File.exist?(original)
          logger.info("#{col}: OK — original at #{original}")
          ok += 1
        else
          legacy = legacy_dirs(site, col).find { |d| Dir.exist?(d) }
          if legacy
            logger.warn("#{col}: NOT migrated — still at legacy path #{legacy}. Run migrate:copy.")
          else
            logger.warn("#{col}: NOT found at new path or any legacy path — '#{site.send(col).identifier}' may be lost.")
          end
          missing += 1
        end
      end

      logger.info("BrandingMigrationVerifyJob complete for tenant #{tenant}: #{ok} OK, #{missing} missing")
    end
  end
end
