# frozen_string_literal: true

module ThemeHomepage
  # rubocop:disable Metrics/ParameterLists
  def initialize(search_service:, response:, collections:, featured_work_list:,
                 featured_collection_list:, current_ability:)
    @search_service = search_service
    @response = response
    @collections = collections
    @featured_work_list = featured_work_list
    @featured_collection_list = featured_collection_list
    @current_ability = current_ability
  end
  # rubocop:enable Metrics/ParameterLists

  def counts
    @counts ||= { collections: Array(@collections).size, works: @response.total }
  end

  def featured_works
    @featured_works ||= readable_featured_works
  end

  def featured_collections
    @featured_collections ||= readable_featured_collections
  end

  # The featured collections when an admin has chosen any, and a browse slice otherwise.
  def collections
    @collections_slice ||= begin
      featured = featured_collections.map { |collection| collection.presenter.solr_document }

      (featured.presence || Array(@collections)).first(FeaturedCollection.feature_limit)
    end
  end

  def collection_works_count(document)
    Hyrax::CollectionPresenter.new(document, @current_ability).total_viewable_works
  end

  private

  # A tenant can remove any facet from the catalog config, and Blacklight
  # raises rather than returning nothing when asked to facet on a field it
  # does not know, so a theme cannot assume a facet exists.
  def facet_items(field, extra_params = {})
    return [] unless @search_service.blacklight_config.facet_fields.key?(field)

    @search_service.facet_field_response(field, { 'facet.mincount' => '1' }.merge(extra_params))
                   .aggregations[field]&.items.to_a
  end

  # FeaturedWorkList and FeaturedCollectionList build their presenters with
  # ability = nil, so anything rendering them must re-check read access.
  def readable_ids(ids)
    return [] if ids.empty?

    (_, documents) = @search_service.fetch(ids, rows: ids.size, fl: 'id')

    documents.map(&:id)
  end

  def readable_featured_works
    featured = @featured_work_list.featured_works
    readable = readable_ids(featured.map { |work| work.presenter.id })

    featured.select { |work| readable.include?(work.presenter.id) }
  end

  def readable_featured_collections
    readable = Array(@collections).map(&:id)

    @featured_collection_list.featured_collections
                             .select { |collection| readable.include?(collection.presenter.id) }
  end
end
