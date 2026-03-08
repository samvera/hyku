# frozen_string_literal: true

module Hyrax
  module FileSetDecorator
    def self.prepended(base)
      base.include Hyrax::Schema(:bulkrax_metadata) if Hyrax.config.file_set_include_metadata? && !base.fields.include?(:bulkrax_identifier)
      base.include Hyrax::ArResource unless base.include?(Hyrax::ArResource)
    end
  end
end

Hyrax::FileSet.prepend Hyrax::FileSetDecorator

# NOTE: Uses ENV rather than Hyrax.config.disable_wings because this line
# executes at class load time, before Hyrax configuration is fully initialized.
Hyrax::ValkyrieLazyMigration.migrating(Hyrax::FileSet, from: ::FileSet) unless ENV["HYRAX_SKIP_WINGS"] == "true"
