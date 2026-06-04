# frozen_string_literal: true

# Shared path helpers for branding migration jobs (copy, verify, cleanup).
# Must be called inside an Apartment::Tenant.switch block — both Hyrax.config.branding_path
# and Hyrax.config.upload_path use Apartment::Tenant.current for tenant scoping.
#
# Path structure:
#   New (branding_path): {branding_base}/{tenant}/{model}/{attachment}/{id}/{style}/{filename}
#   Legacy (upload_path): {upload_base}/{tenant}/{model}/{attachment}/{id}/[{style}/]{filename}
#   Legacy (system):      {rails_root}/public/system/{attachment}/{id}/{style}/{filename}
module BrandingMigrationPaths
  BRANDING_COLUMNS = %i[banner_image logo_image directory_image
                        default_collection_image default_work_image favicon].freeze

  # Directory where the uploader now expects all style files for this column.
  # Mirrors Hyku::BrandingStoreable#store_dir.
  #
  # @param site [Site]
  # @param col [Symbol] one of BRANDING_COLUMNS
  # @return [Pathname, nil] nil when the column has no stored value
  def new_branding_dir(site, col)
    return nil if site.send(col).identifier.blank?

    Hyrax.config.branding_path
         .join(Apartment::Tenant.current, 'site', col.to_s.pluralize)
  end

  # Ordered list of legacy directories that may contain style subdirectories
  # (original/, medium/, thumb/, etc.) or bare files for this column.
  #
  # @param site [Site]
  # @param col [Symbol] one of BRANDING_COLUMNS
  # @return [Array<String>]
  def legacy_dirs(site, col)
    return [] if site.send(col).identifier.blank?

    upload_base = Hyrax.config.upload_path.call.to_s
    [
      # Old upload-path storage (ticket example paths)
      File.join(upload_base, 'site', col.to_s.pluralize, site.id.to_s),
      # Paperclip compat default (public/system) before branding_path override
      Rails.root.join('public', 'system', col.to_s.pluralize, site.id.to_s).to_s
    ]
  end

  # Copies all files from a legacy directory into the new branding directory,
  # preserving relative paths. Bare files (no style subdir) are placed under original/.
  #
  # @param src_dir [String] legacy directory path
  # @param dest_dir [Pathname] new branding directory
  def copy_branding_dir(src_dir, dest_dir)
    Dir.glob("#{src_dir}/**/*").each do |src_file|
      next if File.directory?(src_file)

      rel = Pathname.new(src_file).relative_path_from(src_dir)
      # Files stored without a style subdir (depth 1) belong under original/
      dest_file = rel.each_filename.count == 1 ? dest_dir.join('original', rel) : dest_dir.join(rel)

      next if dest_file.exist?

      FileUtils.mkdir_p(dest_file.dirname)
      FileUtils.cp(src_file, dest_file)
    end
  end
end
