# frozen_string_literal: true

# OVERRIDE: Hyrax v2.9.0
# - add inject_theme_views method for theming
# - add homepage presenter for access to feature flippers
# - add access to content blocks in the show method

module Hyrax
  class ContactFormController < ApplicationController
    # OVERRIDE: Hyrax v2.9.0 Add for theming
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::SearchHelper
    include Blacklight::AccessControls::Catalog
    before_action :build_contact_form
    layout 'homepage'

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

    def new
      # OVERRIDE: Hyrax v2.9.0 Add for theming
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @home_text = ContentBlock.for(:home_text)
      @featured_work_list = FeaturedWorkList.new
      @announcement_text = ContentBlock.for(:announcement)
    end

    def create
      # not spam and a valid form
      if @contact_form.valid?
        ContactMailer.contact(@contact_form).deliver_now
        flash.now[:notice] = 'Thank you for your message!'
        after_deliver
        @contact_form = ContactForm.new
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. '
        flash.now[:error] << @contact_form.errors.full_messages.map(&:to_s).join(", ")
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
        @contact_form = Hyrax::ContactForm.new(contact_form_params)
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
