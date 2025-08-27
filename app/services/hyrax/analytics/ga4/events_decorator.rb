# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1 to pass arguments to the parent class's `initialize` method
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
