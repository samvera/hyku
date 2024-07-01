# frozen_string_literal: true

Hyrax::FileSet.class_eval do
  include Hyrax::Schema(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::Schema(:hyku_file_set_metadata) unless Hyrax.config.flexible?
  include Hyrax::ArResource
end

Hyrax::ValkyrieLazyMigration.migrating(Hyrax::FileSet, from: ::FileSet)
