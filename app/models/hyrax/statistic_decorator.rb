# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to use a different GA key, by default FileDownloadStat uses :totalEvents
#   however this isn't working for because what we get back from Hyrax::Analytics::Results object
#   is a hash with :pageviews instead which doesn't work for our needs.

module Hyrax
  module StatisticDecorator
    extend ActiveSupport::Concern

    class_methods do
      private

      def combined_stats(object, start_date, object_method, ga_key, user_id = nil)
        ga_key = :pageviews if self == FileDownloadStat

        super
      end
    end
  end
end

Hyrax::Statistic.prepend(Hyrax::StatisticDecorator)
