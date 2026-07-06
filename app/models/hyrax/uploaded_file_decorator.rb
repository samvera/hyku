# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to enforce per-tenant upload restraints on the server.
#
# The per-tenant file size limit already reaches the upload widget through
# Hyrax.config.uploader[:maxFileSize] (see AccountSettings#configure_hyrax),
# but nothing enforced it server side, so a direct POST could bypass it. This
# validation checks the tenant's file size limit, accepted content types, and
# storage ceiling whenever a file is saved.
#
# The size and content type checks run on every save because chunked uploads
# append bytes to the same record across several requests and must be
# re-checked as the file grows. The storage ceiling is only checked when new
# file content is being introduced, so later saves of the same record (for
# example linking it to a file set during ingest) do not count it twice.
module Hyrax
  module UploadedFileDecorator
    private

    def enforce_tenant_upload_limits
      return if file.blank? || file.size.to_i.zero?

      [upload_size_error, upload_content_type_error, upload_storage_error]
        .compact.each { |message| errors.add(:base, message) }
    end

    def upload_size_error
      UploadLimitsService.file_size_error(size: file.size, filename: upload_filename)
    end

    def upload_content_type_error
      UploadLimitsService.content_type_error(content_type: upload_content_type,
                                             filename: upload_filename)
    end

    def upload_storage_error
      return unless new_record? || file.cached?

      UploadLimitsService.storage_error(additional_bytes: file.size)
    end

    def upload_filename
      file.file&.filename || 'File'
    end

    # Browsers send application/octet-stream for the chunks of a chunked
    # upload; fall back to the filename to recover a useful content type.
    def upload_content_type
      declared = file.content_type
      return declared if declared.present? && declared != 'application/octet-stream'

      Marcel::MimeType.for(name: upload_filename, declared_type: declared)
    end
  end
end

Hyrax::UploadedFile.prepend(Hyrax::UploadedFileDecorator)
unless Hyrax::UploadedFile._validate_callbacks.any? { |cb| cb.filter == :enforce_tenant_upload_limits }
  Hyrax::UploadedFile.validate :enforce_tenant_upload_limits
end
