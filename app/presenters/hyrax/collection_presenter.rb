# frozen_string_literal: true

# OVERRIDE FILE from Hyrax v2.9.0
# OVERRIDE Hyrax v2.9.0 to add collection methods to collection presenter
require_dependency Hyrax::Engine.root.join('app', 'presenters', 'hyrax', 'collection_presenter').to_s
Hyrax::CollectionPresenter.class_eval do
  # Terms is the list of fields displayed by
  # app/views/collections/_show_descriptions.html.erb
  # OVERRIDE Hyrax - removed size
  def self.terms
    %i[ total_items
        resource_type
        creator contributor
        keyword license
        publisher
        date_created
        subject language
        identifier
        based_near
        related_url]
  end

  def [](key)
    case key
    when :total_items
      total_items
    else
      solr_document.send key
    end
  end

  # Begin Featured Collections Methods
  def collection_featurable?
    user_can_feature_collection? && solr_document.public?
  end

  def display_feature_collection_link?
    collection_featurable? && FeaturedCollection.can_create_another? && !collection_featured?
  end

  def display_unfeature_collection_link?
    collection_featurable? && collection_featured?
  end

  def collection_featured?
    # only look this up if it's not boolean; ||= won't work here
    @collection_featured = FeaturedCollection.where(collection_id: solr_document.id).exists? if @collection_featured.nil?
    @collection_featured
  end

  def user_can_feature_collection?
    current_ability.can?(:create, FeaturedCollection)
  end
  # End Featured Collections Methods
end
