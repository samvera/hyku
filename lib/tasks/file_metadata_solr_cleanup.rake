# frozen_string_literal: true

namespace :hyku do
  namespace :solr do
    desc <<~DESC
      Delete Hyrax::FileMetadata Solr documents for tenants that have opted
      into skip_file_metadata_solr_indexing - it stops new documents from
      being created, but doesn't retroactively remove existing ones.

      Options (all via environment variables):

        PERFORM    Set to "true" to actually delete. Otherwise dry run - reports counts only. (default: false)
        CNAME      Limit to one tenant's cname instead of every opted-in tenant.
    DESC
    task cleanup_file_metadata: :environment do
      perform = ENV['PERFORM'] == 'true'
      accounts = ENV['CNAME'].present? ? Account.where(cname: ENV['CNAME']) : Account.all

      accounts.find_each do |account|
        AccountElevator.switch!(account.cname)
        next unless account.skip_file_metadata_solr_indexing

        count = Hyrax::SolrService.count('has_model_ssim:Hyrax::FileMetadata')
        next if count.zero?

        if perform
          Hyrax::SolrService.delete_by_query('has_model_ssim:Hyrax::FileMetadata')
          Hyrax::SolrService.commit
          puts "#{account.cname}: deleted #{count} Hyrax::FileMetadata documents"
        else
          puts "#{account.cname}: #{count} Hyrax::FileMetadata documents would be deleted (dry run, set PERFORM=true)"
        end
      end
    end
  end
end
