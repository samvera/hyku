# frozen_string_literal: true

module Hyku
  module HomepageHelper
    DESCRIPTION_LENGTH = 250

    def truncate_description(text)
      truncate(text, length: DESCRIPTION_LENGTH, separator: ' ', omission: '...')
    end
  end
end
