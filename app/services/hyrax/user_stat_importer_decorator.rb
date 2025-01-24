# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.1 to use Hyrax.query_service to find the fileset instead of FileSet.find
#   Remove this if https://github.com/samvera/hyrax/pull/6992 gets merged and Hyrax is updated appropriately

module Hyrax
  module UserStatImporterDecorator
    private

    def process_files(stats, user, start_date)
      file_ids_for_user(user).each do |file_id|
        file = Hyrax.query_service.find_by(id: file_id)
        view_stats = extract_stats_for(object: file, from: FileViewStat, start_date: start_date, user: user)
        stats = tally_results(view_stats, :views, stats) if view_stats.present?
        delay
        dl_stats = extract_stats_for(object: file, from: FileDownloadStat, start_date: start_date, user: user)
        stats = tally_results(dl_stats, :downloads, stats) if dl_stats.present?
        delay
      end
    end
  end
end

Hyrax::UserStatImporter.prepend(Hyrax::UserStatImporterDecorator)
