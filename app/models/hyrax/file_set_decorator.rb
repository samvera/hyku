# frozen_string_literal: true

module Hyrax
  module FileSetDecorator
    def self.included(base)
      base.include Hyrax::Schema(:bulkrax_metadata) unless Hyrax.config.file_set_include_metadata?
      base.include Hyrax::ArResource
    end
  end
end

Hyrax::FileSet.prepend Hyrax::FileSetDecorator
Hyrax::ValkyrieLazyMigration.migrating(Hyrax::FileSet, from: ::FileSet)
