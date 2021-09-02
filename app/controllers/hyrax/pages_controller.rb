# frozen_string_literal: true

# OVERRIDE: Hyrax v2.9.0
# - add inject_theme_views method for theming
# - add homepage presenter for access to feature flippers
# - add access to content blocks in the show method

module Hyrax
  # Shows the about and help page
  class PagesController < ApplicationController
    load_and_authorize_resource class: ContentBlock, except: :show
    layout :pages_layout

    # OVERRIDE: Hyrax v2.9.0 Add for theming
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::SearchHelper
    include Blacklight::AccessControls::Catalog

    # OVERRIDE: Adding inject theme views method for theming
    around_action :inject_theme_views

    # OVERRIDE: Hyrax v2.9.0 Add for theming
    # The search builder for finding recent documents
    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    # OVERRIDE: Hyrax v2.9.0 Add for theming
    class_attribute :presenter_class
    # OVERRIDE: Hyrax v2.9.0 Add for theming
    self.presenter_class = Hyrax::HomepagePresenter

    helper Hyrax::ContentBlockHelper

    def show
      @page = ContentBlock.for(params[:key])
      # OVERRIDE: Hyrax v2.9.0 Add for theming
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      @announcement_text = ContentBlock.for(:announcement)
    end

    def edit
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.pages'), hyrax.edit_pages_path
    end

    def update
      respond_to do |format|
        if @page.update(value: update_value_from_params)
          redirect_path = "#{hyrax.edit_pages_path}##{params[:content_block].keys.first}"
          format.html { redirect_to redirect_path, notice: t(:'hyrax.pages.updated') }
        else
          format.html { render :edit }
        end
      end
    end

    private

      def permitted_params
        params.require(:content_block).permit(:about,
                                              :agreement,
                                              :help,
                                              :terms)
      end

      # When a request comes to the controller, it will be for one and
      # only one of the content blocks. Params always looks like:
      #   {'about_page' => 'Here is an awesome about page!'}
      # So reach into permitted params and pull out the first value.
      def update_value_from_params
        permitted_params.values.first
      end

      def pages_layout
        action_name == 'show' ? 'homepage' : 'hyrax/dashboard'
      end

      # OVERRIDE: return collections for theming
      def collections(rows: 6)
        builder = Hyrax::CollectionSearchBuilder.new(self)
                                                .rows(rows)
        response = repository.search(builder)
        response.documents
      rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
        []
      end

      # OVERRIDE: Adding to prepend the theme views into the view_paths
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
