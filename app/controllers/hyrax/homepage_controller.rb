# frozen_string_literal: true

#########################################################################################
#########################################################################################
#
#
# HACK: We have copied over the Hyrax::HomepageController to address Hyku specific
#       customizations.  This controller needs significant refactoring and reconciliation
#       with Hyrax prime.  Note, we are inheriting differently than Hyrax does and
#       there are other adjustments.
#
#
#########################################################################################
#########################################################################################

# OVERRIDE: Hyrax v5.0.0
# - add home_text content block to the index method - Adding themes
# - add inject_theme_views method for theming
# - add all_collections page for IR theme
# - add facet counts for resource types for IR theme

# - add facets to home page - inheriting from CatalogController rather than ApplicationController
# - add search_action_url method from Blacklight 6.23.0 to make facet links to go to /catalog
# - add .sort_by to return collections in alphabetical order by title on the homepage
# - add @featured_collection_list to index method

module Hyrax
  # Changed to inherit from CatalogController for home page facets
  class HomepageController < CatalogController
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::AccessControls::Catalog

    # OVERRIDE: account for Hyku themes
    around_action :inject_theme_views

    # The search builder for finding recent documents
    # Override of Blacklight::RequestBuilders and default CatalogController behavior
    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    class_attribute :presenter_class
    self.presenter_class = Hyrax::HomepagePresenter
    layout 'homepage'
    helper Hyrax::ContentBlockHelper

    # rubocop:disable Metrics/MethodLength
    def index
      # TODO: Maybe consider not setting these ContentBlock.for values; they could just as easily be
      # loaded in the view.
      @featured_researcher = ContentBlock.for(:researcher)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      # OVERRIDE here to add featured collection list
      @featured_collection_list = FeaturedCollectionList.new
      load_shared_info
      recent
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
    # rubocop:enable Metrics/MethodLength

    def browserconfig; end

    def all_collections
      load_shared_info
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

    # shared methods for index and all_collections routes
    def load_shared_info
      @presenter = presenter_class.new(current_ability, collections)
      @marketing_text = ContentBlock.for(:marketing)
      @announcement_text = ContentBlock.for(:announcement)
      @collections = collections(rows: 100_000)
      # rubocop:disable Style/GuardClause
      # TODO: Why not make these helper methods?  As is we rely on a theme to set instance
      # variables.  Which is fragile.
      if home_page_theme == 'institutional_repository'
        ir_counts
        @top_level_collections ||= load_top_level_collections(@collections)
      end
      # rubocop:enable Style/GuardClause
    end

    def load_top_level_collections(colls)
      colls.select { |c| c['member_of_collection_ids_ssim'].nil? }
    end

    # Return 6 collections, sorts by title
    def collections(rows: 6)
      Hyrax::CollectionsService.new(self).search_results do |builder|
        builder.rows(rows)
        builder.merge(sort: "title_ssi")
      end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      []
    end

    # override to show 6 recent items
    def recent(rows: 6)
      (_, @recent_documents) = search_service.search_results do |builder|
        builder.rows(rows)
        builder.merge(sort: sort_field)
      end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      @recent_documents = []
    end

    def ir_counts
      @ir_counts = search_service.facet_field_response('resource_type_sim', "f.resource_type_sim.facet.limit" => "-1")
    end

    # COPIED from Hyrax::HomepageController
    def sort_field
      "date_uploaded_dtsi desc"
    end

    # Add this method to prepend the theme views into the view_paths
    def inject_theme_views
      if home_page_theme && home_page_theme != 'default_home'
        original_paths = view_paths
        home_theme_view_path = Rails.root.join('app', 'views', "themes", home_page_theme.to_s)
        prepend_view_path(home_theme_view_path)
        yield
        # rubocop:disable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
        # Do NOT change this line. This is calling the Rails view_paths=(paths) method and not a variable assignment.
        view_paths=(original_paths)
        # rubocop:enable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
      else
        yield
      end
    end

    # add this method to vary blacklight config and user_params
    def search_service(*_args)
      Hyrax::SearchService.new(
        config: ::CatalogController.new.blacklight_config,
        user_params: params.except(:q, :page),
        scope: self,
        current_ability:,
        search_builder_class:
      )
    end
  end
end
