# frozen_string_literal: true

# Kicks off jobs for each sub-directory in a given directory to clear out unneeded uploads
class CleanupUploadFilesJob < ApplicationJob
  non_tenant_job

  # Only process pair-tree hex directories (00-ff); do not process tenant UUID directories
  # which contain permanent site/branding files (e.g. banner_images), or other protected
  # dirs (uploaded_collection_thumbnails, identity_provider, hyrax).
  HEX_TOP_DIR_PATTERN = /\A[0-9a-f]{2}\z/

  attr_reader :uploads_path
  def perform(delete_ingested_after_days:, uploads_path:, delete_all_after_days: 730)
    @uploads_path = uploads_path
    logger.info(message(delete_ingested_after_days, delete_all_after_days))
    top_level_directories.map do |dir|
      CleanupSubDirectoryJob.perform_later(
        delete_ingested_after_days: delete_ingested_after_days,
        directory: dir,
        delete_all_after_days: delete_all_after_days
      )
    end
  end

  private

    def top_level_directories
      @top_level_directories ||= Dir.glob("#{uploads_path}/*").select do |path|
        File.directory?(path) && File.basename(path).match?(HEX_TOP_DIR_PATTERN)
      end
    end

    def message(delete_ingested_after_days, delete_all_after_days)
      <<~MESSAGE
        Starting cleanup: delete ingested after #{delete_ingested_after_days} days,
        delete all files after #{delete_all_after_days} days.
        Spawning #{top_level_directories.count} cleanup jobs for subdirectories
      MESSAGE
    end
end