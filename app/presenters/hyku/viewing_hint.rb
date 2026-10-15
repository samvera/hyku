# frozen_string_literal: true

module Hyku
  ##
  # Lets a work type choose how IIIF viewers lay out its pages.  A works controller sets
  # `self.iiif_viewing_hint`, which is {.default_viewing_hint} unless it says otherwise; `nil` leaves the hint
  # out, so viewers show one page at a time.  The iiif_manifest gem writes the hint as `viewingHint` in a IIIF
  # v2 manifest and as `behavior` in a v3 one, where `viewingHint` is not a property.
  module ViewingHint
    ##
    # @return [String, nil] the hint a work type gets unless its controller sets its own; an application can
    #   override this to change the default for every work type
    def self.default_viewing_hint
      'paged'
    end

    attr_writer :iiif_viewing_hint

    def iiif_viewing_hint
      defined?(@iiif_viewing_hint) ? @iiif_viewing_hint : ViewingHint.default_viewing_hint
    end

    # @return [String, Array<String>, nil] a v3 manifest's `behavior` is a list
    def viewing_hint
      return iiif_viewing_hint if iiif_viewing_hint.blank? || iiif_version.to_i < 3

      Array(iiif_viewing_hint)
    end

    # The hint is part of the manifest, so changing it gives the manifest a new version
    def version(seen: Set.new)
      [super(seen: seen), 'viewing_hint', *iiif_viewing_hint].join('|')
    end
  end
end
