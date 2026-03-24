# frozen_string_literal: true

# Kicks off a CleanupSubDirectoryJob for the Carrierwave uploaded-file staging
# directory under the tenant's upload root.
class CleanupUploadFilesJob < ApplicationJob
  non_tenant_job

  CARRIERWAVE_SUBDIR = File.join("hyrax", "uploaded_file", "file").freeze

  attr_reader :uploads_path, :tenant
  def perform(delete_ingested_after_days:, uploads_path:, delete_all_after_days: 730, tenant: nil)
    @uploads_path = uploads_path
    @tenant = tenant
    carrierwave_dir = File.join(uploads_path, CARRIERWAVE_SUBDIR)

    unless Dir.exist?(carrierwave_dir)
      logger.info("No Carrierwave directory at #{carrierwave_dir}; nothing to clean")
      return
    end

    logger.info(message(carrierwave_dir, delete_ingested_after_days, delete_all_after_days))

    CleanupSubDirectoryJob.perform_later(
      delete_ingested_after_days: delete_ingested_after_days,
      directory: carrierwave_dir,
      delete_all_after_days: delete_all_after_days,
      tenant: tenant
    )
  end

  private

  def message(carrierwave_dir, delete_ingested_after_days, delete_all_after_days)
    <<~MESSAGE
      Starting cleanup of #{carrierwave_dir}:
      delete ingested after #{delete_ingested_after_days} days,
      delete all files after #{delete_all_after_days} days.
    MESSAGE
  end
end
