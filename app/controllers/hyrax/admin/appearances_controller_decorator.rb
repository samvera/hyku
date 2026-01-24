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
        return_tab = params[:return_tab] || extract_tab_from_referer || 'logo_image'
        form = update_appearance_form
        return redirect_to_custom_defaults(return_tab, form) if params[:save_as_custom_defaults].present?

        reindex_resources
        redirect_to("#{hyrax.admin_appearance_path}##{return_tab}", notice: t('.flash.success'))
      end

      private

      def update_appearance_form
        form = form_class.new(update_params)
        form.banner_image = update_params[:banner_image] if update_params[:banner_image].present?
        form.logo_image = update_params[:logo_image] if update_params[:logo_image].present?
        form.update!

        update_params.each do |key, value|
          ContentBlock.update_block(name: key.to_s, value: value) if key.to_s.include?('color') && value.present?
        end

        form
      end

      def redirect_to_custom_defaults(return_tab, form)
        form.save_as_custom_defaults!
        redirect_to("#{hyrax.admin_appearance_path}##{return_tab}",
                    notice: 'Custom default colors have been saved. These will be used when you click "Restore All Defaults".')
      end

      def reindex_resources
        return unless update_params['default_collection_image'] || update_params['default_work_image']

        if update_params['default_collection_image']
          ReindexCollectionsJob.perform_later
          ReindexAdminSetsJob.perform_later
        end

        ReindexWorksJob.perform_later if update_params['default_work_image']
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

      def extract_tab_from_referer
        return nil unless request.referer
        # Extract tab from referer URL (e.g., /admin/appearance#color)
        match = request.referer.match(/#(\w+)$/)
        match ? match[1] : nil
      end
    end
  end
end

Hyrax::Admin::AppearancesController.prepend(Hyrax::Admin::AppearancesControllerDecorator)
Hyrax::Admin::AppearancesController.form_class = Hyku::Forms::Admin::Appearance
