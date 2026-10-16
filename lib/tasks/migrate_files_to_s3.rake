# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :hyku do
  desc <<~DESC
    Move disk-stored original files (disk:// identifiers) to the S3 repository
    storage adapter. Re-runnable: shrine:// files are skipped. Never deletes the disk copy.
    Env: DRY_RUN=true to preview, TENANT=<cname> for one tenant, LIMIT=<n> per tenant.
  DESC
  task migrate_files_to_s3: :environment do
    abort 'Set REPOSITORY_S3_STORAGE=true (and the bucket variables) first.' unless Valkyrie::StorageAdapter.storage_adapters.key?(:repository_s3)

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'false'))
    limit = ENV['LIMIT']&.to_i
    s3_storage = Valkyrie::StorageAdapter.find(:repository_s3)
    counts = Hash.new(0)

    puts "[DRY RUN] No changes will be made.\n\n" if dry_run

    accounts = ENV['TENANT'].present? ? Account.where(cname: ENV['TENANT']) : Account.all
    accounts.find_each do |account|
      AccountElevator.switch!(account.cname)
      puts "=== Tenant: #{account.cname} ==="
      tenant_migrated = 0

      Hyrax.query_service.find_all_of_model(model: Hyrax::FileSet).each do |file_set|
        break if limit && tenant_migrated >= limit

        original = Hyrax.custom_queries.find_original_file(file_set:)
        next unless original

        identifier = original.file_identifier.to_s
        if identifier.start_with?('shrine://')
          counts[:skipped] += 1
          next
        end

        unless identifier.start_with?('disk://')
          puts "  SKIP  #{file_set.id} - unrecognised storage: #{identifier}"
          counts[:skipped] += 1
          next
        end

        disk_path = identifier.delete_prefix('disk://')
        unless File.exist?(disk_path)
          puts "  ERROR #{file_set.id} - file missing on disk: #{disk_path}"
          counts[:errors] += 1
          next
        end

        filename = Array(original.original_filename).first || File.basename(disk_path)
        puts "  #{'[DRY RUN] ' if dry_run}Migrating #{file_set.id} (#{filename})"
        tenant_migrated += 1
        next if dry_run

        File.open(disk_path, 'rb') do |io|
          uploaded = s3_storage.upload(file: io, original_filename: filename, resource: file_set)
          original.file_identifier = uploaded.id
          Hyrax.persister.save(resource: original)
        end
        Hyrax.index_adapter.save(resource: file_set)
        counts[:migrated] += 1
      rescue StandardError => e
        puts "  ERROR #{file_set.id} - #{e.class}: #{e.message}"
        counts[:errors] += 1
      end

      Hyrax::SolrService.commit
    end

    puts "\nMigrated: #{counts[:migrated]}  Skipped: #{counts[:skipped]}  Errors: #{counts[:errors]}"
  end
end
# rubocop:enable Metrics/BlockLength
