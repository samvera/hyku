# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0. The gem's create action calls save! and lets a
# validation failure surface as a 500 with no message. When an upload fails
# validation (the per-tenant file size, content type, and storage limits, or
# the virus scan), discard it and report the failure in the per-file error
# format the upload widget already renders, so the depositor sees why the
# file was rejected.
module Hyrax
  module UploadsControllerDecorator
    def create
      super
    rescue ActiveRecord::RecordInvalid
      upload_error = @upload.errors.full_messages.to_sentence
      upload_name = @upload.file&.file&.filename || params[:files]&.first.try(:original_filename)
      @upload.destroy if @upload.persisted?
      render json: { files: [{ name: upload_name, error: upload_error }] }
    end
  end
end

Hyrax::UploadsController.prepend(Hyrax::UploadsControllerDecorator)
