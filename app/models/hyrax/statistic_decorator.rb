# frozen_string_literal: true

# OVERRIDE Hyrax hyrax-v3.5.0 to require Hyrax::Pageview so the method below doesn't fail

Hyrax::Pageview # rubocop:disable Lint/Void

module Hyrax
  module StatisticClassDecorator
    # Hyrax::Pageview is sent to Hyrax::Analytics.profile as #hyrax__pageview
    # see Legato::ProfileMethods.method_name_from_klass
    def ga_statistics(start_date, object)
      path = polymorphic_path(object)
      profile = Hyrax::Analytics.profile
      unless profile
        Rails.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
        return []
      end
      # OVERRIDE Hyrax hyrax-v3.5.0
      profile.hyrax__pageview(sort: 'date',
                              start_date: start_date,
                              end_date: Date.yesterday,
                              limit: 10_000)
             .for_path(path)
    end
  end
end

Hyrax::Statistic.singleton_class.send(:prepend, Hyrax::StatisticClassDecorator)
