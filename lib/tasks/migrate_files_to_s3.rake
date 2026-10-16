# frozen_string_literal: true

# Thin wrappers: the work lives in Hyku::S3Migration::* and the MigrateTenantFilesToS3Job /
# MigrateFileSetToS3Job jobs. See docs/migrating-files-to-s3.md.
# rubocop:disable Metrics/BlockLength, Metrics/MethodLength, Metrics/AbcSize
namespace :hyku do
  def s3_migration_flag(name, default: 'false')
    ActiveModel::Type::Boolean.new.cast(ENV.fetch(name, default))
  end

  def s3_migration_each_tenant
    on_error = lambda do |account, error|
      puts "  TENANT ERROR #{account.cname} - #{error.class}: #{error.message}"
    end
    failed = Hyku::S3Migration::Tenants.each(tenant: ENV['TENANT'], on_error:) do |account|
      puts "=== Tenant: #{account.cname} ==="
      yield account
    end
    puts "\nTenants that failed (rerun with TENANT=<cname>): #{failed.join(', ')}" if failed.any?
  end

  def s3_migration_require_s3!
    abort 'Set REPOSITORY_S3_STORAGE=true (and the bucket variables) first.' unless Valkyrie::StorageAdapter.storage_adapters.key?(:repository_s3)
  end

  def s3_migration_inline(dry_run:)
    counts = Hash.new(0)
    limit = ENV['LIMIT']&.to_i
    s3_migration_each_tenant do |account|
      done = 0
      Hyrax.query_service.find_all_of_model(model: Hyku::S3Migration.file_set_class).each do |file_set|
        break if limit && done >= limit

        original = Hyrax.custom_queries.find_original_file(file_set:)
        next unless original

        result = Hyku::S3Migration::FileMigrator.new(file_set:, original:, dry_run:, tenant: account.cname).call
        counts[result.status] += 1
        next if result.status == :already_migrated

        done += 1
        puts "  #{result.status.to_s.upcase} #{file_set.id} #{result.message}".rstrip
      rescue StandardError => e
        counts[:error] += 1
        puts "  ERROR #{file_set.id} - #{e.class}: #{e.message}"
      end
    end
    puts "\n#{counts.map { |status, count| "#{status}: #{count}" }.join('  ')}"
  end

  desc <<~DESC
    Move disk-stored original files (disk:// ids) to the S3 repository adapter. By default this
    enqueues jobs (one per file set; watch your workers, and set S3_MIGRATION_QUEUE to use a
    dedicated queue). Each upload is verified by SHA-256 read-back, and against the stored
    characterization checksum, before the identifier is switched; the disk copy is never touched.
    Env: DRY_RUN=true runs inline and only reports; INLINE=true runs inline for real;
    TENANT=<cname>; LIMIT=<n> files per tenant.
  DESC
  task migrate_files_to_s3: :environment do
    s3_migration_require_s3!
    dry_run = s3_migration_flag('DRY_RUN')

    if dry_run || s3_migration_flag('INLINE')
      puts "[DRY RUN] No changes will be made.\n\n" if dry_run
      s3_migration_inline(dry_run:)
    else
      s3_migration_each_tenant do |account|
        MigrateTenantFilesToS3Job.perform_later(limit: ENV['LIMIT']&.to_i)
        puts "  enqueued MigrateTenantFilesToS3Job for #{account.cname}"
      end
    end
  end

  desc <<~DESC
    Read-only audit of originals already in S3: object readable, recorded size and stored MD5 match.
    Get zero problems before deleting anything from disk. Env: TENANT=<cname>, LIMIT=<n> per tenant.
  DESC
  task verify_files_in_s3: :environment do
    counts = Hash.new(0)
    limit = ENV['LIMIT']&.to_i
    s3_migration_each_tenant do
      checked = 0
      Hyrax.query_service.find_all_of_model(model: Hyku::S3Migration.file_set_class).each do |file_set|
        break if limit && checked >= limit

        original = Hyrax.custom_queries.find_original_file(file_set:)
        next unless original

        result = Hyku::S3Migration::Auditor.new(original:).call
        counts[result.status] += 1
        next if result.status == :not_in_s3

        checked += 1
        puts "  PROBLEM #{file_set.id} - #{result.problems.join('; ')}" if result.status == :problem
      rescue StandardError => e
        counts[:problem] += 1
        puts "  PROBLEM #{file_set.id} - #{e.class}: #{e.message}"
      end
    end
    puts "\nOK: #{counts[:ok]}  Problems: #{counts[:problem]}  Not yet in S3: #{counts[:not_in_s3]}"
  end

  desc 'Read-only report of file storage per tenant by file use and scheme (disk, shrine, ...). Env: TENANT=<cname>.'
  task report_file_storage: :environment do
    totals = Hash.new { |hash, key| hash[key] = [0, 0] }
    s3_migration_each_tenant do
      Hyku::S3Migration::StorageReport.call.each do |key, (count, bytes)|
        totals[key][0] += count
        totals[key][1] += bytes
      end
    end
    puts "\nuse | scheme | files | GB"
    totals.sort.each { |(use, scheme), (count, bytes)| puts "#{use} | #{scheme} | #{count} | #{(bytes / 1e9).round(2)}" }
  end

  def s3_migration_each_entry
    tenant = nil
    Hyku::S3Migration::Manifest.new.each_entry do |entry|
      AccountElevator.switch!(tenant = entry[:tenant]) unless tenant == entry[:tenant]
      yield entry
    end
  end

  def s3_migration_run_quarantine(label, action)
    counts = Hash.new(0)
    s3_migration_each_entry do |entry|
      quarantine = Hyku::S3Migration::Quarantine.new(entry, apply: s3_migration_flag('APPLY'),
                                                            verify_sha: s3_migration_flag('VERIFY_SHA', default: 'true'))
      status = quarantine.public_send(action)
      counts[status] += 1
      puts "  #{label} #{entry[:file_set_id]}" if %i[quarantined rolled_back].include?(status)
    rescue StandardError => e
      counts[:error] += 1
      puts "  ERROR #{entry[:file_set_id]} - #{e.class}: #{e.message}"
    end
    puts "\n#{counts.map { |status, count| "#{status}: #{count}" }.join('  ')}"
  end

  desc <<~DESC
    Move the disk copies of manifested files to <storage>/.quarantine after re-checking the database
    and the S3 object against the manifest. Dry run unless APPLY=true. VERIFY_SHA=false skips the hash.
  DESC
  task quarantine_migrated_disk_files: :environment do
    s3_migration_require_s3!
    puts "[DRY RUN] Nothing will be moved. Set APPLY=true to move.\n\n" unless s3_migration_flag('APPLY')
    s3_migration_run_quarantine('Quarantine', :quarantine)
  end

  desc 'Undo a migration from the manifest (restores the disk copy and id). Dry run unless APPLY=true.'
  task rollback_migrated_files: :environment do
    s3_migration_require_s3!
    puts "[DRY RUN] Nothing will change. Set APPLY=true to roll back.\n\n" unless s3_migration_flag('APPLY')
    s3_migration_run_quarantine('Rolling back', :rollback)
  end

  desc 'Permanently delete quarantined files older than MIN_AGE_DAYS (default 14). Dry run unless APPLY=true.'
  task purge_quarantine: :environment do
    apply = s3_migration_flag('APPLY')
    puts "[DRY RUN] Nothing will be deleted. Set APPLY=true to delete.\n\n" unless apply
    purged, kept = Hyku::S3Migration::Quarantine.purge(apply:, min_age: ENV.fetch('MIN_AGE_DAYS', '14').to_f.days)
    puts "#{apply ? 'Deleted' : 'Would delete'}: #{purged}  Too recent: #{kept}"
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/MethodLength, Metrics/AbcSize
