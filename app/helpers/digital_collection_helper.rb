# frozen_string_literal: true

# Helpers for the digital collection theme's home and show pages.
module DigitalCollectionHelper
  def dc_home
    theme_home(DigitalCollection::HomepagePresenter)
  end
end
