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

  desc <<~DESC
    Delete cached analytics stats (FileViewStat, FileDownloadStat, WorkViewStat,
    UserStat) dated, cached or refreshed on or after SINCE, across every tenant, so the stats
    pages and the nightly UserStatCollectionJob fetch them again from each
    tenant's own analytics property.

    For stats cached while concurrent requests could read another tenant's
    analytics config, which may have come from the wrong property.

    Options (all via environment variables):

      SINCE    When suspect caching began, as YYYY-MM-DD. Required.
      DRY_RUN  Set to "true" to only report how many rows would be deleted.
               (default: false)
  DESC
  task purge_cached_stats: :environment do
    since = Date.iso8601(ENV.fetch('SINCE'))
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', false))
    purge = lambda do |klass, label|
      scope = klass.where(date: since..).or(klass.where(created_at: since..)).or(klass.where(updated_at: since..))
      count = dry_run ? scope.count : scope.delete_all
      puts "#{label}: #{dry_run ? 'would delete' : 'deleted'} #{count} #{klass} rows"
    end

    # Excluded from Apartment, so one table serves every tenant
    purge.call(UserStat, 'all tenants')
    Account.find_each do |account|
      Apartment::Tenant.switch(account.tenant) do
        [FileViewStat, FileDownloadStat, WorkViewStat].each { |klass| purge.call(klass, account.cname) }
      end
    rescue StandardError => e
      Rails.logger.error("hyku:purge_cached_stats - #{account.cname} failed: #{e.message}")
    end
  end
end
