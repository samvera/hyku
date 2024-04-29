# frozen_string_literal: true

# OVERRIDE HYRAX v5.0.1 to turn loc into a string for the location lookup,
# otherwise it'll error.
module Hyrax
  ##
  # Indexes properties common to Hyrax::Resource types
  module LocationIndexerDecorator
    def based_near_label_lookup(locations)
      locations.map do |loc|
        location_service.full_label(loc.to_s)
      end
    end
  end
end

Hyrax::LocationIndexer.prepend(Hyrax::LocationIndexerDecorator)
