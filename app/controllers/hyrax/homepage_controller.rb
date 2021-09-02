# frozen_string_literal: true

# OVERRIDE: Hyrax v2.9.0 to add home_text content block to the index method - Adding themes
# OVERRIDE: Hyrax v2.9.0 from Hyrax v2.9.0 to add facets to home page - inheriting from
# CatalogController rather than ApplicationController
# OVERRIDE: Hyrax v2.9.0 from Hyrax v2.9.0 to add inject_theme_views method for theming
# OVERRIDE: Hyrax v2.9.0 to add search_action_url method from Blacklight 6.23.0 to make facet links to go to /catalog
# OVERRIDE: Hyrax v2.9.0 to add .sort_by to return collections in alphabetical order by title on the homepage
# OVERRIDE: Hyrax v2.9.0 add all_collections page for IR theme
# OVERRIDE: Hyrax v2.9.0 to add facet counts for resource types for IR theme

module Hyrax
  # Changed to inherit from CatalogController for home page facets
  class HomepageController < CatalogController
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
      ir_counts if home_page_theme == 'institutional_repository'

      # override hyrax v2.9.0 added for facets on homepage - Adding Themes
      (@response, @document_list) = search_results(params)

      respond_to do |format|
        format.html { store_preferred_view }
        format.rss  { render layout: false }
        format.atom { render layout: false }
        format.json do
          @presenter = Blacklight::JsonPresenter.new(@response,
                                                     @document_list,
                                                     facets_from_request,
                                                     blacklight_config)
        end
        additional_response_formats(format)
        document_export_formats(format)
      end
    end

    def all_collections
      @presenter = presenter_class.new(current_ability, collections)
      @marketing_text = ContentBlock.for(:marketing)
      @announcement_text = ContentBlock.for(:announcement)
      @collections = collections(rows: 100_000)
      ir_counts if home_page_theme == 'institutional_repository'
    end

    # Added from Blacklight 6.23.0 to change url for facets on home page
    protected

      # Default route to the search action (used e.g. in global partials). Override this method
      # in a controller or in your ApplicationController to introduce custom logic for choosing
      # which action the search form should use
      def search_action_url(options = {})
        # Rails 4.2 deprecated url helpers accepting string keys for 'controller' or 'action'
        main_app.search_catalog_path(options)
      end

    private

      # Return 6 collections
      def collections(rows: 6)
        builder = Hyrax::CollectionSearchBuilder.new(self)
                                                .rows(rows)
        response = repository.search(builder)
        # adding .sort_by to return collections in alphabetical order by title on the homepage
        response.documents.sort_by(&:title)
      rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        []
      end

      def recent
        # grab any recent documents
        (_, @recent_documents) = search_results(q: '', sort: sort_field, rows: 6)
      rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        @recent_documents = []
      end

      # OVERRIDE: Hyrax v2.9.0 to add facet counts for resource types for IR theme
      def ir_counts
        @ir_counts = get_facet_field_response('resource_type_sim', {}, "f.resource_type_sim.facet.limit" => "-1")
      end

      def sort_field
        "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc"
      end

      # Add this method to prepend the theme views into the view_paths
      def inject_theme_views
        if home_page_theme && home_page_theme != 'default_home'
          original_paths = view_paths
          home_theme_view_path = Rails.root.join('app', 'views', "themes", home_page_theme.to_s)
          prepend_view_path(home_theme_view_path)
          yield
          # rubocop:disable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
          view_paths=(original_paths)
          # rubocop:enable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
        else
          yield
        end
      end
  end
end
