# frozen_string_literal: true

module Hyrax
  # OVERRIDE Hyrax v5.2.0 to apply per-file metadata that arrives as
  # ActionController::Parameters.
  #
  # Remove once https://github.com/samvera/hyrax/pull/7529 is merged
  module DepositWizardWorkUploadsHandlerDecorator
    private

    def file_set_args(file, file_set_params = {})
      extra = file_set_params.respond_to?(:to_unsafe_h) ? file_set_params.to_unsafe_h : file_set_params.to_h
      super(file, extra.symbolize_keys)
    end
  end
end

Hyrax::WorkUploadsHandler.prepend(Hyrax::DepositWizardWorkUploadsHandlerDecorator)
