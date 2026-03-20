# frozen_string_literal: true

# Finds uploaded files in a directory, determines whether they should be deleted, and deletes appropriate files.
class CleanupSubDirectoryJob < ApplicationJob
  non_tenant_job

  # Assumptions:
  # The second to last element in the path is the ID of the associated FileSet
  # The directory has a pair-tree structure
  attr_reader :delete_ingested_after_days, :delete_all_after_days, :directory, :files_checked, :files_deleted
  def perform(delete_ingested_after_days:, directory:, delete_all_after_days: 730)
    @directory = directory
    @delete_ingested_after_days = delete_ingested_after_days
    @delete_all_after_days = delete_all_after_days
    @files_checked = 0
    @files_deleted = 0
    delete_files
    delete_empty_directories
    logger.info("Completed #{directory}: checked #{@files_checked}, deleted #{@files_deleted}")
  end

  private

  def delete_files
    Dir.glob("#{directory}/**/*").each do |path|
      next unless should_be_deleted?(path)

      File.delete(path)
      @files_deleted += 1
      logger.info("Checked #{@files_checked}, deleted #{@files_deleted} files") if (@files_checked % 100).zero?
    end
  end

  def delete_empty_directories
    # Find all UUID-level directories (deepest level)
    Dir.glob("#{directory}/*/*/*/*").select { |path| File.directory?(path) }.each do |dir|
      FileUtils.rmdir(dir, parents: true)
    rescue Errno::ENOTEMPTY
      next
    end

    logger.info("Completed empty directory cleanup for #{directory}")
  end

  def should_be_deleted?(path)
    return false unless File.file?(path)

    return true if very_old?(path)

    ingested_and_old_enough?(path)
  end

  def ingested_and_old_enough?(path)
    file_older_than?(path, delete_ingested_after_days) && fileset_created?(path)
  end

  def very_old?(path)
    file_older_than?(path, delete_all_after_days)
  end

  def file_older_than?(path, days)
    File.mtime(path) < (Time.zone.now - days.to_i.days)
  end

  def fileset_created?(path)
    @files_checked += 1
    Account.find_each do |account|
      return true if tenant_has_file_set?(file_set_id: path.split('/')[-2], tenant: account.tenant)
    end

    false
  end

  def tenant_has_file_set?(file_set_id:, tenant:)
    Apartment::Tenant.switch(tenant) do
      return true if active_fedora_file_set_exists?(file_set_id)
      return true if valkyrie_file_set_exists?(file_set_id)
    end

    false
  rescue StandardError => e
    logger.error("Error checking FileSet #{file_set_id} in tenant #{tenant}: #{e.message}")
  end

  def active_fedora_file_set_exists?(file_set_id)
    FileSet.exists?(file_set_id)
  end

  def valkyrie_file_set_exists?(file_set_id)
    resource = Hyrax.query_service.find_by(id: Valkyrie::ID.new(file_set_id))
    resource.is_a?(Hyrax::FileSet)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    false
  end
end
