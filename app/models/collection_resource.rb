# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResource < Hyrax::PcdmCollection
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:collection_resource)
  include Hyrax::ArResource

  Hyrax::ValkyrieLazyMigration.migrating(self, from: ::Collection)

  # This module provides the #public?, #private?, #restricted? methods; consider
  # contributing this back to Hyrax; but that decision requires further discussion
  # on architecture.
  # @see https://samvera.slack.com/archives/C0F9JQJDQ/p1705421588370699 Slack discussion thread.
  include Hyrax::Permissions::Readable

  include WithPermissionTemplateShim

  prepend OrderAlready.for(:creator)
end