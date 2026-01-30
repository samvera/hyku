# frozen_string_literal: true

module Hyku
  module HomepageHelper
    FEATURED_DESCRIPTION_LENGTH = 250

    def truncate_featured_description(text)
      truncate(text, length: FEATURED_DESCRIPTION_LENGTH, separator: ' ', omission: '...')
    end
  end
end
