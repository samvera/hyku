# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to add selectable themes

module Hyrax
  module Admin
    module AppearancesControllerDecorator
      def show
        # TODO: make selected font the font that show in select box
        # TODO add body and headline font to the import url
        add_breadcrumbs
        @form = form_class.new
        @fonts = [@form.headline_font, @form.body_font]
        @home_theme_information = YAML.load_file(Hyku::Application.path_for('config/home_themes.yml'))
        @show_theme_information = YAML.load_file(Hyku::Application.path_for('config/show_themes.yml'))
        @home_theme_names = load_home_theme_names
        @show_theme_names = load_show_theme_names
        @search_themes = load_search_themes

        flash[:alert] = t('hyrax.admin.appearances.show.forms.custom_css.warning')
      end

      def update
        form = form_class.new(update_params)
        form.banner_image = update_params[:banner_image] if update_params[:banner_image].present?
        form.logo_image = update_params[:logo_image] if update_params[:logo_image].present?
        form.update!

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

Hyrax::Admin::AppearancesController.prepend(Hyrax::Admin::AppearancesControllerDecorator)
Hyrax::Admin::AppearancesController.form_class = Hyku::Forms::Admin::Appearance
