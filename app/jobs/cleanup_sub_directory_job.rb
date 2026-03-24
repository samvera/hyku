# frozen_string_literal: true

# Walks the Carrierwave uploaded-file staging directory
# (<uploads>/<tenant>/hyrax/uploaded_file/file/) and deletes files whose
# corresponding Hyrax::UploadedFile record shows they have been ingested
# (file_set_uri is present) and are old enough, or that are orphaned and
# very old.
class CleanupSubDirectoryJob < ApplicationJob
  non_tenant_job

  attr_reader :delete_ingested_after_days, :delete_all_after_days, :directory, :tenant, :files_checked, :files_deleted

  def perform(delete_ingested_after_days:, directory:, delete_all_after_days: 730, tenant: nil)
    @directory = directory
    @delete_ingested_after_days = delete_ingested_after_days
    @delete_all_after_days = delete_all_after_days
    @tenant = tenant
    @files_checked = 0
    @files_deleted = 0
    process_upload_directories
    delete_empty_directories
    logger.info("Completed #{directory}: checked #{@files_checked}, deleted #{@files_deleted}")
  end

  private

  def process_upload_directories
    Dir.glob("#{directory}/*").each do |upload_dir|
      next unless File.directory?(upload_dir)

      uploaded_file_id = File.basename(upload_dir)
      process_upload_dir(upload_dir, uploaded_file_id)
    end
  end

  def process_upload_dir(upload_dir, uploaded_file_id)
    Dir.glob("#{upload_dir}/*").each do |path|
      next unless File.file?(path)
      next unless should_be_deleted?(path, uploaded_file_id)

      File.delete(path)
      @files_deleted += 1
      logger.info("Checked #{@files_checked}, deleted #{@files_deleted} files") if (@files_deleted % 100).zero?
    end
  end

  def delete_empty_directories
    Dir.glob("#{directory}/*").select { |path| File.directory?(path) }.each do |dir|
      FileUtils.rmdir(dir)
    rescue Errno::ENOTEMPTY
      next
    end

    logger.info("Completed empty directory cleanup for #{directory}")
  end

  def should_be_deleted?(path, uploaded_file_id)
    return true if very_old?(path)

    ingested_and_old_enough?(path, uploaded_file_id)
  end

  def ingested_and_old_enough?(path, uploaded_file_id)
    file_older_than?(path, delete_ingested_after_days) && ingested?(uploaded_file_id)
  end

  def very_old?(path)
    file_older_than?(path, delete_all_after_days)
  end

  def file_older_than?(path, days)
    File.mtime(path) < (Time.zone.now - days.to_i.days)
  end

  def ingested?(uploaded_file_id)
    @files_checked += 1
    record = if tenant.present?
               Apartment::Tenant.switch(tenant) { Hyrax::UploadedFile.find_by(id: uploaded_file_id) }
             else
               Hyrax::UploadedFile.find_by(id: uploaded_file_id)
             end

    return false if record.nil?

    record.file_set_uri.present?
  end
end
