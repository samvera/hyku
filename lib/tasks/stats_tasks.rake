# frozen_string_literal: true

namespace :hyku do
  desc <<~DESC
    Delete redundant zero-count rows from the stats cache tables (FileViewStat,
    FileDownloadStat, WorkViewStat), across every tenant.

    Wraps Hyrax::StatsPruner (see samvera/hyrax#7649), which has no concept of
    Apartment tenants on its own - `rake tenantize:task[...]` isn't a substitute
    here, since Account#switch only swaps the Solr/Fedora/Redis/host context,
    never the Apartment/Postgres tenant a stats query needs to be scoped to.

    Options (all via environment variables):

      BATCH_SIZE   Rows deleted per batch, per table, per tenant. (default: 50000)
      DRY_RUN      Set to "true" to only report how many rows would be deleted.
                   (default: false)
  DESC
  task prune_zero_stats: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))
    batch_size = ENV.fetch('BATCH_SIZE', 50_000).to_i

    Account.find_each do |account|
      Apartment::Tenant.switch!(account.tenant)

      { FileViewStat => :file_id, FileDownloadStat => :file_id, WorkViewStat => :work_id }.each do |klass, id_column|
        Rails.logger.info("hyku:prune_zero_stats - #{account.cname}: pruning #{klass}...")
        Hyrax::StatsPruner.call(klass:, id_column:, dry_run:, batch_size:)
      end
    rescue StandardError => e
      Rails.logger.error("hyku:prune_zero_stats - #{account.cname} failed: #{e.message}")
    end
  end
end
