# frozen_string_literal: true

# Orchestrates per-tenant Hyrax upload staging cleanup by enqueueing
# CleanupUploadFilesJob for every tenant that has local staging files.
#
# Two scenarios are handled:
#
# 1. Known tenants (including those that have since switched to S3): always
#    checks the local filesystem path so that staging files left behind after
#    an S3 migration are not silently ignored.
#
# 2. Extra / legacy base paths (EXTRA_UPLOAD_PATHS): scans additional upload
#    root directories for UUID-named subdirectories. Useful when HYRAX_UPLOAD_PATH
#    changed and old files are sitting at the former location.
#
# See lib/tasks/uploads_cleanup.rake for usage and ENV-variable documentation.
class UploadsCleanupService
  TENANT_UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  def initialize(
    delete_ingested_after_days: 180,
    delete_all_after_days: 730,
    extra_upload_paths: [],
    include_orphaned_tenant_dirs: false
  )
    @delete_ingested_after_days = delete_ingested_after_days
    @delete_all_after_days = delete_all_after_days
    @extra_upload_paths = Array(extra_upload_paths).map(&:to_s).reject(&:empty?)
    @include_orphaned_tenant_dirs = include_orphaned_tenant_dirs
    @queued_paths = Set.new
  end

  def run
    clean_known_tenants
    @extra_upload_paths.each { |path| scan_extra_path(path) }
  end

  private

  def clean_known_tenants
    Account.find_each { |account| enqueue_tenant_cleanup(local_staging_root(account.tenant), account.tenant) }
  end

  # Returns the local filesystem path for a tenant's Hyrax upload staging tree.
  # Used regardless of whether the tenant currently uses S3, because files from
  # before an S3 migration are still on disk and must be cleaned up.
  def local_staging_root(tenant)
    if ENV['HYRAX_UPLOAD_PATH'].present?
      File.join(ENV['HYRAX_UPLOAD_PATH'], tenant)
    else
      Rails.root.join('public', 'uploads', tenant).to_s
    end
  end

  # Enqueue CleanupUploadFilesJob for +uploads_path+ if the CarrierWave staging
  # subdirectory exists. No-ops if the path was already queued this run.
  def enqueue_tenant_cleanup(uploads_path, tenant)
    return if @queued_paths.include?(uploads_path)

    staging_dir = File.join(uploads_path, CleanupUploadFilesJob::CARRIERWAVE_SUBDIR)
    unless Dir.exist?(staging_dir)
      Rails.logger.debug "Skipping #{tenant}: no staging directory at #{staging_dir}"
      return
    end

    Rails.logger.debug "Enqueueing cleanup for #{tenant} → #{uploads_path}"
    CleanupUploadFilesJob.perform_later(
      delete_ingested_after_days: @delete_ingested_after_days,
      uploads_path: uploads_path,
      delete_all_after_days: @delete_all_after_days,
      tenant: tenant
    )
    @queued_paths << uploads_path
  end

  # Walk +base_path+ for UUID-named subdirectories and enqueue cleanup for each.
  def scan_extra_path(base_path)
    unless Dir.exist?(base_path)
      Rails.logger.debug "Skipping extra path #{base_path}: directory not found"
      return
    end

    known_tenants = Account.pluck(:tenant).to_set

    Dir.children(base_path).sort.each do |entry|
      next unless TENANT_UUID_PATTERN.match?(entry)

      dir = File.join(base_path, entry)
      next unless File.directory?(dir)

      if known_tenants.include?(entry)
        enqueue_tenant_cleanup(dir, entry)
      elsif @include_orphaned_tenant_dirs
        enqueue_orphaned_cleanup(dir, entry)
      else
        Rails.logger.debug "Skipping orphaned tenant dir #{entry} (pass INCLUDE_ORPHANED_TENANT_DIRS=true to clean)"
      end
    end

    # Handle files stored directly under base_path with no tenant subdirectory. This happens
    # when Apartment::Tenant.current returned nil/empty at upload time, causing File.join to
    # collapse the tenant segment and write staging files directly into the upload root.
    enqueue_orphaned_cleanup(base_path, "(no tenant)") if @include_orphaned_tenant_dirs
  end

  # Enqueue cleanup for a UUID directory whose tenant schema no longer exists.
  # Since no DB lookup is possible, CleanupSubDirectoryJob will never find a matching
  # Hyrax::UploadedFile record and will treat every file as orphaned. The only threshold
  # that matters is delete_all_after_days; delete_ingested_after_days is set to the same
  # value for consistency. The caller must opt in via include_orphaned_tenant_dirs.
  def enqueue_orphaned_cleanup(uploads_path, tenant_id)
    return if @queued_paths.include?(uploads_path)

    staging_dir = File.join(uploads_path, CleanupUploadFilesJob::CARRIERWAVE_SUBDIR)
    unless Dir.exist?(staging_dir)
      Rails.logger.debug "Skipping orphaned tenant #{tenant_id}: no staging directory at #{staging_dir}"
      return
    end

    Rails.logger.debug "Enqueueing orphaned tenant cleanup for #{tenant_id} → #{uploads_path} " \
         "(all files older than #{@delete_all_after_days} days)"
    CleanupUploadFilesJob.perform_later(
      delete_ingested_after_days: @delete_all_after_days,
      uploads_path: uploads_path,
      delete_all_after_days: @delete_all_after_days,
      tenant: nil
    )
    @queued_paths << uploads_path
  end
end
