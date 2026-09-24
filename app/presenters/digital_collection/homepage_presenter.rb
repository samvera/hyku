# frozen_string_literal: true

module DigitalCollection
  class HomepagePresenter
    include ThemeHomepage

    COLLECTION_FIELD = 'member_of_collection_ids_ssim'

    def hero_collections
      @hero_collections ||= featured_collections.map do |featured|
        Hyrax::CollectionPresenter.new(featured.presenter.solr_document, @current_ability)
      end
    end

    def browse_collections
      @browse_collections ||= Array(@collections).sort_by { |document| ActiveSupport::Inflector.transliterate(Array(document['title_tesim']).first.to_s).downcase }
    end

    def browse_works_count(document)
      browse_works_counts.fetch(document.id, 0)
    end

    private

    def browse_works_counts
      @browse_works_counts ||= begin
        (response, _documents) = @search_service.search_results do |builder|
          builder.merge(rows: 0, facet: true, 'facet.field' => [COLLECTION_FIELD], 'facet.limit' => -1, 'facet.mincount' => 1)
        end

        response.dig('facet_counts', 'facet_fields', COLLECTION_FIELD).to_a.each_slice(2).to_h
      end
    end
  end
end
