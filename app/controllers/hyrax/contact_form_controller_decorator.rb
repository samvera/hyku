# frozen_string_literal: true

# OVERRIDE: Hyrax v5.2.0
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
    include Hyku::HomePageThemesBehavior

    prepended do
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
      ir_counts if home_page_theme == 'institutional_repository'
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def create
      # Override to include captcha
      # Negative captcha handles text inputs (name, email, subject, message) to prevent spam
      # Select/dropdown fields (category, contact_method) are processed normally since they:
      # 1. Have predefined values making them less vulnerable to spam
      # 2. Don't work well with negative captcha's encryption
      form_values = @captcha.values.merge(
        category: params.dig(:contact_form, :category),
        contact_method: params.dig(:contact_form, :contact_method)
      )

      @contact_form = model_class.new(form_values)
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

    def ir_counts
      @ir_counts = search_service.facet_field_response('resource_type_sim', "f.resource_type_sim.facet.limit" => "-1")
    end

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

    def setup_negative_captcha
      @captcha = NegativeCaptcha.new(
        # A secret key entered in environment.rb. 'rake secret' will give you a good one.
        secret: ENV.fetch('NEGATIVE_CAPTCHA_SECRET', 'default-value-change-me'),
        spinner: request.remote_ip,
        # Only protect text input fields with negative captcha
        # Select/dropdown fields are handled separately in the create action
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
