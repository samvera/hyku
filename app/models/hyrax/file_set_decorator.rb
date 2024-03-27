# frozen_string_literal: true

Hyrax::FileSet.class_eval do
  include Hyrax::ArResource
end

Hyrax::ValkyrieLazyMigration.migrating(Hyrax::FileSet, from: ::FileSet)
