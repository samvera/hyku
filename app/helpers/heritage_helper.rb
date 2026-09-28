# frozen_string_literal: true

# Helpers for the heritage theme's home and show pages.
module HeritageHelper
  def hrt_home
    theme_home(Heritage::HomepagePresenter)
  end

  def hrt_date_created(object)
    Array(object.date_created).first.presence
  end
end
