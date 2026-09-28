# frozen_string_literal: true

module Hyrax
  module UploadsControllerDecorator
    extend ActiveSupport::Concern

    prepended do
      before_action :enforce_upload_limit!, only: [:create]
    end

    private

    def enforce_upload_limit!
      limit = tenant_upload_limit
      return if limit.blank?

      incoming = params[:files]&.first
      return unless incoming.respond_to?(:original_filename)

      return if assembled_size(incoming) <= limit

      render_upload_too_large(limit)
    end

    def assembled_size(incoming)
      content_range = request.headers['CONTENT-RANGE']
      return incoming.size if params[:id].blank? || content_range.blank?

      current = bytes_already_uploaded
      begin_of_chunk = content_range[/\ (.*?)-/, 1].to_i

      begin_of_chunk == current ? current + incoming.size : incoming.size
    end

    def bytes_already_uploaded
      path = Hyrax::UploadedFile.find_by(id: params[:id])&.file&.path
      return 0 if path.blank? || !File.exist?(path)

      File.size(path)
    end

    def tenant_upload_limit
      raw = Site.account&.file_size_limit.to_s.strip
      return nil unless raw.match?(/\A\d+\z/)

      limit = raw.to_i
      limit.positive? ? limit : nil
    end

    def render_upload_too_large(limit)
      render json: {
        files: [{
          name: params[:files]&.first&.original_filename,
          error: "File exceeds the #{ActiveSupport::NumberHelper.number_to_human_size(limit)} upload limit for this site."
        }]
      }, status: :payload_too_large
    end
  end
end

Hyrax::UploadsController.prepend(Hyrax::UploadsControllerDecorator)
