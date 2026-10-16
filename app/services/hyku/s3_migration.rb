# frozen_string_literal: true

module Hyku
  module S3Migration
    # The Valkyrie file set class this app is configured with (Hyrax.config.file_set_model).
    def self.file_set_class
      Hyrax.config.valkyrie_file_set_class
    end
  end
end
