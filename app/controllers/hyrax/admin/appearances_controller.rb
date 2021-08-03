# frozen_string_literal: true

module Hyrax
  module Admin
    class AppearancesController < ApplicationController
      before_action :require_permissions
      with_themed_layout 'dashboard'
      class_attribute :form_class
      self.form_class = Hyrax::Forms::Admin::Appearance

      def show
        # TODO: make selected font the font that show in select box
        # TODO add body and headline font to the import url
        add_breadcrumbs
        @form = form_class.new
        @fonts = [@form.headline_font, @form.body_font]
        @home_theme_information = YAML.load_file('config/home_themes.yml')
        @show_theme_information = YAML.load_file('config/show_themes.yml')
        @home_theme_names = load_home_theme_names
        @show_theme_names = load_show_theme_names
        @search_themes = load_search_themes

        flash[:alert] = t('hyrax.admin.appearances.show.forms.custom_css.warning')
      end

      def update
        form_class.new(update_params).update!

        if update_params['default_collection_image']
          # Reindex all Collections and AdminSets to apply new default collection image
          ReindexCollectionsJob.perform_later
          ReindexAdminSetsJob.perform_later
        end

        if update_params['default_work_image']
          # Reindex all Works to apply new default work image
          ReindexWorksJob.perform_later
        end

        redirect_to({ action: :show }, notice: t('.flash.success'))
      end

      private

        def update_params
          params.require(:admin_appearance).permit(form_class.permitted_params)
        end

        def require_permissions
          authorize! :update, :appearance
        end

        def add_breadcrumbs
          add_breadcrumb t(:'hyrax.controls.home'), root_path
          add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
          add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
          add_breadcrumb t(:'hyrax.admin.sidebar.appearance'), request.path
        end

        def load_home_theme_names
          home_theme_names = []
          @home_theme_information.each do |theme, value_hash|
            value_hash.each do |key, value|
              home_theme_names << [value, theme] if key == 'name'
            end
          end
          home_theme_names
        end

        def load_show_theme_names
          show_theme_names = []
          @show_theme_information.each do |theme, value_hash|
            value_hash.each do |key, value|
              show_theme_names << [value, theme] if key == 'name'
            end
          end
          show_theme_names
        end

        def load_search_themes
          {
            'List view' => 'list_view',
            'Gallery view' => 'gallery_view'
          }
        end
    end
  end
end
