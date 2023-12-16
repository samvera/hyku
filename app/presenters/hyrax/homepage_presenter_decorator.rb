# frozen_string_literal: true

# OVERRIDE Hyrax 5.0 to hide features via flipper
# hide featured researcher
# hide featured works
# hide recently uploaded
# hide share button
module Hyrax
  module HomepagePresenterDecorator
    def display_share_button?
      Flipflop.show_share_button? && current_ability.can_create_any_work? ||
        Flipflop.show_share_button? && user_unregistered?
    end

    def display_featured_researcher?
      Flipflop.show_featured_researcher?
    end

    def display_featured_works?
      Flipflop.show_featured_works?
    end

    def display_recently_uploaded?
      Flipflop.show_recently_uploaded?
    end
  end
end

Hyrax::HomepagePresenter.prepend(Hyrax::HomepagePresenterDecorator)
