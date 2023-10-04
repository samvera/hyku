# frozen_string_literal: true

# OVERRIDE: Hyrax v3.4.0
# - add inject_theme_views method for theming
# - add homepage presenter for access to feature flippers
# - add access to content blocks in the show method
# - add @featured_collection_list to new method

module Hyrax
  class ContactFormController < ApplicationController
    # OVERRIDE: Hyrax v3.4.0 Add for theming
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::SearchHelper
    include Blacklight::AccessControls::Catalog
    before_action :build_contact_form
    layout 'homepage'
    # OVERRIDE: Adding inject theme views method for theming
    around_action :inject_theme_views
    class_attribute :model_class
    self.model_class = Hyrax::ContactForm
    before_action :setup_negative_captcha, only: %i[new create]
    # OVERRIDE: Hyrax v3.4.0 Add for theming
    # The search builder for finding recent documents
    # Override of Blacklight::RequestBuilders
    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    # OVERRIDE: Hyrax v3.4.0 Add for theming
    class_attribute :presenter_class
    # OVERRIDE: Hyrax v3.4.0 Add for theming
    self.presenter_class = Hyrax::HomepagePresenter

    helper Hyrax::ContentBlockHelper

    def new
      # OVERRIDE: Hyrax v3.4.0 Add for theming
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      # OVERRIDE: Hyrax 3.4.0 add @featured_collection_list
      @featured_collection_list = FeaturedCollectionList.new
      @announcement_text = ContentBlock.for(:announcement)
    end

    def create
      # not spam, form is valid, and captcha is valid
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
                            @contact_form.errors.full_messages.map(&:to_s).join(", ") +
                            "" + @captcha.error
      end
      render :new
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end

    def handle_create_exception(exception)
      logger.error("Contact form failed to send: #{exception.inspect}")
      flash.now[:error] = 'Sorry, this message was not delivered.'
      render :new
    end

    # Override this method if you want to perform additional operations
    # when a email is successfully sent, such as sending a confirmation
    # response to the user.
    def after_deliver; end

    private

      def build_contact_form
        @contact_form = model_class.new(contact_form_params)
      end

      def contact_form_params
        return {} unless params.key?(:contact_form)
        params.require(:contact_form).permit(:contact_method, :category, :name, :email, :subject, :message)
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
          params: params
        )
      end
  end
end
