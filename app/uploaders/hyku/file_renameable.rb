# frozen_string_literal: true

module Hyku
  # Generates unique filenames with tenant prefix to prevent cross-tenant overwrites.
  # Memoizes the filename so the main file and its versions (medium, thumb) stay consistent.
  module FileRenameable
    # Returns a unique filename with tenant prefix and timestamp.
    # Uses a separate ivar so CarrierWave's @filename (original name) does not override it.
    #
    # @return [String, nil] Memoized filename (e.g. "tenant_uuid_1234567890.png"), or nil if original_filename is blank.
    def filename
      return if original_filename.blank?

      @renameable_filename ||= parent_or_generate_filename
    end

    private

    # Returns the parent's filename for version uploaders, or a new unique filename for the main uploader.
    #
    # @return [String] Parent uploader's filename when this is a version (medium/thumb), otherwise the result of generate_unique_filename.
    def parent_or_generate_filename
      if parent_version.present?
        parent_version.filename
      else
        generate_unique_filename
      end
    end

    # Builds a unique filename from tenant id and timestamp.
    #
    # @return [String] Filename in the form "account_tenant_timestamp.extension" (e.g. "cde32e20-..._1770156595.png").
    def generate_unique_filename
      account_id = model.try(:account).try(:tenant) || Apartment::Tenant.current
      time_stamp = Time.now.utc.to_i
      extension = File.extname(original_filename)

      [account_id, time_stamp].join('_') + extension
    end
  end
end
