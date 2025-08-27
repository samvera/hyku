# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1
# This decorator fixes an ArgumentError in the Hyrax::Analytics::Ga4::Events class.
# The original `initialize` method did not pass its arguments to the parent class's
# `initialize` method, causing a crash when creating new event queries.
module Hyrax
  module Analytics
    module Ga4
      module EventsDecorator
        def initialize(start_date:,
                       end_date:,
                       dimensions: [{ name: 'eventName' }, { name: 'contentType' }, { name: 'contentId' }],
                       metrics: [{ name: 'eventCount' }])
          super(start_date: start_date, end_date: end_date, dimensions: dimensions, metrics: metrics)
        end
      end
    end
  end
end

Hyrax::Analytics::Ga4::Events.prepend(Hyrax::Analytics::Ga4::EventsDecorator)
