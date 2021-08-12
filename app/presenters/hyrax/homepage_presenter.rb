# frozen_string_literal: true

# Override from hyrax 2.5.1 to add methods to:
# hide featured researcher
# hide featured works
# hide recently uploaded
# hide share button
module Hyrax
  class HomepagePresenter
    class_attribute :create_work_presenter_class
    self.create_work_presenter_class = Hyrax::SelectTypeListPresenter
    attr_reader :current_ability, :collections

    def initialize(current_ability, collections)
      @current_ability = current_ability
      @collections = collections
    end

    # OVERRIDE: Hyrax v2.9.0 to removed: @return [Boolean] If the
    #   display_share_button_when_not_logged_in? is activated, then
    #   return true since we are utilizing the feature flipper
    #   Flipflop.show_share_button? in Hyku.

    # @return [Boolean] If the current user is a guest
    #   and the feature flipper is enabled or if the signed in
    #   user has permission to create at least one kind of work
    #   and the feature flipper is enabled.

    def display_share_button?
      Flipflop.show_share_button? && current_ability.can_create_any_work? ||
        Flipflop.show_share_button? && user_unregistered?
    end

    # A presenter for selecting a work type to create
    # this is needed here because the selector is in the header on every page
    def create_work_presenter
      @create_work_presenter ||= create_work_presenter_class.new(current_ability.current_user)
    end

    def create_many_work_types?
      create_work_presenter.many?
    end

    def draw_select_work_modal?
      display_share_button? && create_many_work_types?
    end

    def first_work_type
      create_work_presenter.first_model
    end

    # changed to add feature flag for featured researcher
    def display_featured_researcher?
      Flipflop.show_featured_researcher?
    end

    # changed to add feature flag for featured work
    def display_featured_works?
      Flipflop.show_featured_works?
    end

    # changed to add feature flag for recently uploaded
    def display_recently_uploaded?
      Flipflop.show_recently_uploaded?
    end

    private

      def user_unregistered?
        current_ability.current_user.new_record? ||
          current_ability.current_user.guest?
      end
  end
end
