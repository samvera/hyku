# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResource < Hyrax::PcdmCollection
  if Hyrax.config.collection_include_metadata?
    include Hyrax::Schema(:basic_metadata)
    include Hyrax::Schema(:bulkrax_metadata)
    include Hyrax::Schema(:collection_resource)
    include Hyrax::Schema(:with_thumbnail)
  end
  include Hyrax::ArResource

  Hyrax::ValkyrieLazyMigration.migrating(self, from: ::Collection)

  # This module provides the #public?, #private?, #restricted? methods; consider
  # contributing this back to Hyrax; but that decision requires further discussion
  # on architecture.
  # @see https://samvera.slack.com/archives/C0F9JQJDQ/p1705421588370699 Slack discussion thread.
  include Hyrax::Permissions::Readable

  include WithPermissionTemplateShim

  prepend OrderAlready.for(:creator) unless Hyrax.config.flexible?

  ##
  # @!group Methods to Extract

  ##
  # @return [Enumerator]
  def members_of
    return [] unless persisted?

    Hyrax.query_service.custom_queries.find_members_of(collection: self)
  end

  ##
  # @return [Array]
  def member_collection_ids
    return [] unless persisted?

    Hyrax.query_service.custom_queries.find_child_collection_ids(resource: self).to_a
  end

  def collection_type
    Hyrax::CollectionType.for(collection: self)
  end
  # @!endgroup Class Attributes
  ##
end
