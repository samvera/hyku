# frozen_string_literal: true

# OVERRIDE Hyrax hyrax-v3.5.0 to require Hyrax::Download so the method below doesn't fail

Hyrax::Download # rubocop:disable Lint/Void

module FileDownloadStatDecorator
  # Hyrax::Download is sent to Hyrax::Analytics.profile as #hyrax__download
  # see Legato::ProfileMethods.method_name_from_klass
  def ga_statistics(start_date, file)
    profile = Hyrax::Analytics.profile
    unless profile
      Hyrax.logger.error("Google Analytics profile has not been established. Unable to fetch statistics.")
      return []
    end
    # OVERRIDE Hyrax hyrax-v3.5.0
    profile.hyrax__download(sort: 'date',
                            start_date:,
                            end_date: Date.yesterday,
                            limit: 10_000)
           .for_file(file.id)
  end
end

FileDownloadStat.singleton_class.send(:prepend, FileDownloadStatDecorator)
