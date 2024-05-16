# frozen_string_literal: true

Hyrax::FileSet.class_eval do
  include Hyrax::Schema(:bulkrax_metadata)
  include Hyrax::Schema(:hyku_file_set_metadata)
  include Hyrax::ArResource
end

Hyrax::ValkyrieLazyMigration.migrating(Hyrax::FileSet, from: ::FileSet)
