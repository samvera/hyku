# frozen_string_literal: true

# OVERRIDE: Hyrax v5.0.0rc2
# - adds inject_theme_views method for theming
# - adds homepage presenter for access to feature flippers
# - adds access to content blocks in the show method
# - adds @featured_collection_list to new method
# - adds captcha
module Hyrax
  module ContactFormControllerDecorator
    extend ActiveSupport::Concern

    # OVERRIDE: Add for theming
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::AccessControls::Catalog

    prepended do
      # OVERRIDE: Adding inject theme views method for theming
      around_action :inject_theme_views
      before_action :setup_negative_captcha, only: %i[new create]

      # OVERRIDE: Add for theming
      class_attribute :presenter_class
      self.presenter_class = Hyrax::HomepagePresenter

      helper Hyrax::ContentBlockHelper
    end

    # OVERRIDE: Add for theming
    # The search builder for finding recent documents
    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    def new
      # OVERRIDE: Add for theming
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      @featured_collection_list = FeaturedCollectionList.new
      @announcement_text = ContentBlock.for(:announcement)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create
      # not spam and a valid form
      # Override to include captcha
      @captcha.values[:category] = params[:contact_form][:category]
      @captcha.values[:contact_method] = params[:contact_form][:contact_method]
      @captcha.values[:subject] = params[:contact_form][:subject]
      @contact_form = model_class.new(@captcha.values)
      if @contact_form.valid? && @captcha.valid?
        ContactMailer.contact(@contact_form).deliver_now
        flash.now[:notice] = 'Thank you for your message!'
        after_deliver
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. ' +
                            @contact_form.errors.full_messages.map(&:to_s).join(", ")
      end
      render :new
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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

    # OVERRIDE: Adding to prepend the theme views into the view_paths
    def inject_theme_views
      if home_page_theme && home_page_theme != 'default_home'
        original_paths = view_paths
        Hyku::Application.theme_view_path_roots.each do |root|
          home_theme_view_path = File.join(root, 'app', 'views', "themes", home_page_theme.to_s)
          prepend_view_path(home_theme_view_path)
        end
        yield
        # rubocop:disable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
        # Do NOT change this line. This is calling the Rails view_paths=(paths) method and not a variable assignment.
        view_paths=(original_paths)
        # rubocop:enable Lint/UselessAssignment, Layout/SpaceAroundOperators, Style/RedundantParentheses
      else
        yield
      end
    end

    def setup_negative_captcha
      @captcha = NegativeCaptcha.new(
        # A secret key entered in environment.rb. 'rake secret' will give you a good one.
        secret: ENV.fetch('NEGATIVE_CAPTCHA_SECRET', 'default-value-change-me'),
        spinner: request.remote_ip,
        # Whatever fields are in your form
        fields: %i[name email subject message],
        # If you wish to override the default CSS styles (position: absolute; left: -2000px;)
        # used to position the fields off-screen
        css: "display: none",
        params:
      )
    end
  end
end

Hyrax::ContactFormController.prepend(Hyrax::ContactFormControllerDecorator)
