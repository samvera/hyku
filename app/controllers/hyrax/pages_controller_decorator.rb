# frozen_string_literal: true

# OVERRIDE: Hyrax v5.2.0
# - add inject_theme_views method for theming
# - add homepage presenter for access to feature flippers
# - add access to content blocks in the show method
# - adds @featured_collection_list to show method

module Hyrax
  # Shows the about and help page
  module PagesControllerDecorator
    extend ActiveSupport::Concern

    # OVERRIDE: Add for theming
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::AccessControls::Catalog
    include Hyku::HomePageThemesBehavior

    prepended do
      # OVERRIDE: Hyrax v5.0.0rc2 Add for theming
      class_attribute :presenter_class
      self.presenter_class = Hyrax::HomepagePresenter
    end

    # OVERRIDE: Add for theming
    # The search builder for finding recent documents
    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    def show
      super

      # OVERRIDE: Additional for theming
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      @featured_collection_list = FeaturedCollectionList.new
      @announcement_text = ContentBlock.for(:announcement)
      ir_counts if home_page_theme == 'institutional_repository'
    end

    private

    # OVERRIDE: return collections for theming
    # Return 6 collections, sorts by title
    def collections(rows: 6)
      Hyrax::CollectionsService.new(self).search_results do |builder|
        builder.rows(rows)
        builder.merge(sort: "title_ssi")
      end
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      []
    end

    # OVERRIDE: Hyrax v5.0.1 to add facet counts for resource types for IR theme
    def ir_counts
      @ir_counts = search_service.facet_field_response('resource_type_sim', "f.resource_type_sim.facet.limit" => "-1")
    end
  end
end

Hyrax::PagesController.prepend(Hyrax::PagesControllerDecorator)
