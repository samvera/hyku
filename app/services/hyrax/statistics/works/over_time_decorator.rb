# frozen_string_literal: true

module Hyrax
  module Statistics
    module Works
      module OverTimeDecorator
        def points
          return super unless non_wings_valkyrie?

          Enumerator.new(size) do |y|
            x = @x_min
            while x <= @x_max
              y.yield [@x_output.call(x), query_service.find_by_date_created(@x_min, x).count]
              x += @delta_x.days
            end
          end
        end

        private

        def non_wings_valkyrie?
          Hyrax.config.use_valkyrie? && Hyrax.config.disable_wings
        end
      end
    end
  end
end

Hyrax::Statistics::Works::OverTime.prepend(Hyrax::Statistics::Works::OverTimeDecorator)
