# frozen_string_literal: true

# Evaluates the per-tenant upload restraints configured through AccountSettings:
#
# * +file_size_limit+ - the maximum size in bytes for a single file
# * +allowed_content_types+ - a comma separated list of accepted MIME types;
#   a trailing wildcard subtype such as "image/*" is supported
# * +storage_limit+ - a ceiling in bytes on the tenant's total stored content
#
# Each check returns a translated, user facing error message when the
# candidate upload violates the tenant's configuration, or +nil+ when the
# upload is allowed. Blank settings preserve the current behavior: every
# content type is accepted and storage is not capped. All checks are no-ops
# when no tenant account is present.
class UploadLimitsService
  FILE_SIZE_FIELD = 'file_size_lts'

  class << self
    # @param size [Integer] candidate file size in bytes
    # @param filename [String, nil] used in the error message
    # @return [String, nil]
    def file_size_error(size:, filename: nil)
      return if account.blank?

      limit = account.file_size_limit.to_i
      return if limit <= 0 || size.to_i <= limit

      I18n.t('hyku.upload_limits.file_size_exceeded', filename:, limit: human_size(limit))
    end

    # @param content_type [String, nil] candidate MIME type
    # @param filename [String, nil] used in the error message
    # @return [String, nil]
    def content_type_error(content_type:, filename: nil)
      return if account.blank?

      allowed = allowed_content_types
      return if allowed.empty? || allowed_type?(content_type, allowed)

      I18n.t('hyku.upload_limits.content_type_not_allowed',
             filename:, content_type:, allowed_types: allowed.join(', '))
    end

    # @param additional_bytes [Integer] bytes the candidate upload would add
    # @return [String, nil]
    def storage_error(additional_bytes: 0)
      return if account.blank?

      limit = account.storage_limit.to_i
      return if limit <= 0
      return if current_storage_usage + additional_bytes.to_i <= limit

      I18n.t('hyku.upload_limits.storage_limit_reached', limit: human_size(limit))
    end

    # Total bytes already stored in the current tenant, aggregated in Solr
    # from the file size indexed on each FileSet. Content that has not been
    # ingested and indexed yet (for example files still in the staging area)
    # is not counted.
    #
    # @return [Integer]
    def current_storage_usage
      response = Hyrax::SolrService.get('has_model_ssim:FileSet',
                                        rows: 0,
                                        stats: true,
                                        'stats.field' => FILE_SIZE_FIELD)
      response.dig('stats', 'stats_fields', FILE_SIZE_FIELD, 'sum').to_i
    end

    private

    def account
      Site.account
    end

    def allowed_content_types
      account.allowed_content_types.to_s.split(',').map(&:strip).reject(&:empty?)
    end

    def allowed_type?(content_type, allowed)
      return false if content_type.blank?

      candidate = content_type.to_s.downcase
      allowed.any? do |allowed_type|
        if allowed_type.end_with?('/*')
          candidate.start_with?(allowed_type.downcase.delete_suffix('*'))
        else
          candidate == allowed_type.downcase
        end
      end
    end

    def human_size(bytes)
      ActiveSupport::NumberHelper.number_to_human_size(bytes)
    end
  end
end
