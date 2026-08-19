# frozen_string_literal: true

module Heritage
  class HomepagePresenter
    include ThemeHelper

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
        readable = theme_readable_ids(featured.map { |work| work.presenter.id })

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

    def collections
      @collections_slice ||= if featured_collections.any?
                               featured_collections.map(&:presenter)
                             else
                               Array(@collections).first(FeaturedCollection.feature_limit)
                             end
    end
  end
end
