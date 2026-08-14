# frozen_string_literal: true

module PracticeResearch
  class HomepagePresenter
    SUBJECT_LIMIT = 16

    def initialize(search_service:, response:, collections:, featured_work_list:, featured_collection_list:)
      @search_service = search_service
      @response = response
      @collections = collections
      @featured_work_list = featured_work_list
      @featured_collection_list = featured_collection_list
    end

    def counts
      @counts ||= { collections: Array(@collections).size, works: @response.total }
    end

    def featured_works
      @featured_works ||= begin
        featured = @featured_work_list.featured_works
        readable = readable_ids(featured.map { |work| work.presenter.id })

        featured.select { |work| readable.include?(work.presenter.id) }
      end
    end

    def featured_collections
      @featured_collections ||= begin
        readable = Array(@collections).map(&:id)

        @featured_collection_list.featured_collections
                                 .select { |collection| readable.include?(collection.presenter.id) }
      end
    end

    def work_types
      @work_types ||= model_counts.sort_by { |_model, count| -count }.to_h
    end

    def subjects
      @subjects ||= @search_service.facet_field_response(
        'subject_sim', 'facet.mincount' => '1', "f.subject_sim.facet.limit" => SUBJECT_LIMIT.to_s
      ).aggregations['subject_sim']&.items.to_a
    end

    def collection_work_counts
      @collection_work_counts ||= featured_collections.to_h do |collection|
        [collection.presenter.id, collection_work_count(collection.presenter.id)]
      end
    end

    private

    def facets
      @facets ||= @search_service.facet_field_response(
        'has_model_ssim', 'facet.mincount' => '1', 'f.has_model_ssim.facet.limit' => '-1'
      )
    end

    def model_counts
      works = ::Hyrax::ModelRegistry.work_rdf_representations

      facets.aggregations['has_model_ssim']
            .items
            .select { |item| works.include?(item.value) }
            .to_h { |item| [item.value, item.hits] }
    end

    def collection_work_count(collection_id)
      (response, _documents) = @search_service.search_results do |builder|
        builder.rows(0)
        builder.merge(q: "{!terms f=member_of_collection_ids_ssim}#{collection_id}", fl: 'id')
      end

      response.total
    end

    def readable_ids(ids)
      return [] if ids.empty?

      (_, documents) = @search_service.fetch(ids, rows: ids.size, fl: 'id')

      documents.map(&:id)
    end
  end
end
