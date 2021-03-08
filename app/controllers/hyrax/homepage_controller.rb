# Copied from Hyrax v2.9.0 to add home_text content block to the index method - Adding themes
module Hyrax
  class HomepageController < ApplicationController
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::SearchHelper
    include Blacklight::AccessControls::Catalog

    around_action :inject_theme_views

    # The search builder for finding recent documents
    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    class_attribute :presenter_class
    self.presenter_class = Hyrax::HomepagePresenter
    layout 'homepage'
    helper Hyrax::ContentBlockHelper

    # override hyrax v2.9.0 added @home_text - Adding Themes
    def index
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      @announcement_text = ContentBlock.for(:announcement)
      recent
    end

    private

      # Return 5 collections
      def collections(rows: 5)
        builder = Hyrax::CollectionSearchBuilder.new(self)
                                                .rows(rows)
        response = repository.search(builder)
        response.documents
      rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        []
      end

      def recent
        # grab any recent documents
        (_, @recent_documents) = search_results(q: '', sort: sort_field, rows: 4)
      rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        @recent_documents = []
      end

      def sort_field
        "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc"
      end

      def inject_theme_views
        if home_page_theme && home_page_theme != 'default_home'
          original_paths = view_paths
          home_theme_view_path = Rails.root.join('app', 'views', "themes", home_page_theme.to_s)
          prepend_view_path(home_theme_view_path)
          yield
          view_paths=(original_paths)
        else
          yield
        end
      end
  end
end
