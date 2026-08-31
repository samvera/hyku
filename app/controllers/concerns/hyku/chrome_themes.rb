# frozen_string_literal: true

module Hyku
  # The themes whose chrome covers the catalog, the advanced searches, the
  # content pages and the collection and file set shows. A theme that predates
  # that work keeps hyrax's own views on those pages, so its layout and its
  # partials only have to hold up where they always did. A new theme opts in
  # by naming itself here.
  module ChromeThemes
    HOME = %w[practice_research heritage screening_room].freeze
    SHOW = %w[practice_research_show heritage_show screening_room_show].freeze

    def self.home?(theme)
      HOME.include?(theme.to_s)
    end

    def self.show?(theme)
      SHOW.include?(theme.to_s)
    end
  end
end
