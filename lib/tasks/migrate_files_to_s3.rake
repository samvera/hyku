# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :hyku do
  def s3_migration_each_original(tenant: ENV['TENANT'], limit: ENV['LIMIT']&.to_i)
    accounts = tenant.present? ? Account.where(cname: tenant) : Account.all
    accounts.find_each do |account|
      AccountElevator.switch!(account.cname)
      puts "=== Tenant: #{account.cname} ==="
      yielded = 0

      Hyrax.query_service.find_all_of_model(model: Hyrax::FileSet).each do |file_set|
        break if limit && yielded >= limit

        original = Hyrax.custom_queries.find_original_file(file_set:)
        next unless original

        yielded += 1 if yield(file_set, original)
      end
      Hyrax::SolrService.commit
    end
  end

  desc <<~DESC
    Move disk-stored original files (disk:// identifiers) to the S3 repository
    storage adapter. Each upload is read back from S3 and its SHA-256 compared to the
    disk file before the identifier is switched; a mismatch deletes the upload and leaves
    the file on disk. Re-runnable (shrine:// files are skipped). Never deletes the disk copy.
    Env: DRY_RUN=true to preview, TENANT=<cname> for one tenant, LIMIT=<n> files per tenant.
  DESC
  task migrate_files_to_s3: :environment do
    abort 'Set REPOSITORY_S3_STORAGE=true (and the bucket variables) first.' unless Valkyrie::StorageAdapter.storage_adapters.key?(:repository_s3)

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'false'))
    s3_storage = Valkyrie::StorageAdapter.find(:repository_s3)
    counts = Hash.new(0)

    puts "[DRY RUN] No changes will be made.\n\n" if dry_run

    s3_migration_each_original do |file_set, original|
      identifier = original.file_identifier.to_s
      if identifier.start_with?('shrine://')
        counts[:skipped] += 1
        next false
      end

      unless identifier.start_with?('disk://')
        puts "  SKIP  #{file_set.id} - unrecognised storage: #{identifier}"
        counts[:skipped] += 1
        next false
      end

      disk_path = identifier.delete_prefix('disk://')
      unless File.exist?(disk_path)
        puts "  ERROR #{file_set.id} - file missing on disk: #{disk_path}"
        counts[:errors] += 1
        next false
      end

      filename = Array(original.original_filename).first || File.basename(disk_path)
      puts "  #{'[DRY RUN] ' if dry_run}Migrating #{file_set.id} (#{filename})"
      next true if dry_run

      begin
        disk_sha256 = Digest::SHA256.file(disk_path).hexdigest
        uploaded = File.open(disk_path, 'rb') { |io| s3_storage.upload(file: io, original_filename: filename, resource: file_set) }
        s3_file = s3_storage.find_by(id: uploaded.id)
        s3_sha256 = s3_file.checksum(digests: [Digest::SHA256.new]).first

        unless s3_file.size.to_i == File.size(disk_path) && s3_sha256 == disk_sha256
          s3_storage.delete(id: uploaded.id)
          puts "  ERROR #{file_set.id} - S3 copy does not match disk (size/SHA-256); upload removed, file left on disk"
          counts[:errors] += 1
          next false
        end

        original.file_identifier = uploaded.id
        Hyrax.persister.save(resource: original)
        Hyrax.index_adapter.save(resource: file_set)
        counts[:migrated] += 1
        true
      rescue StandardError => e
        puts "  ERROR #{file_set.id} - #{e.class}: #{e.message}"
        counts[:errors] += 1
        false
      end
    end

    puts "\nMigrated: #{counts[:migrated]}  Skipped: #{counts[:skipped]}  Errors: #{counts[:errors]}"
  end

  desc <<~DESC
    Read-only audit of originals already in S3 (shrine://): the object must exist, match the
    recorded size, and match the stored MD5 checksum where one is present. Run it and get zero
    problems before deleting anything from disk.
    Env: TENANT=<cname> for one tenant, LIMIT=<n> files per tenant.
  DESC
  task verify_files_in_s3: :environment do
    counts = Hash.new(0)

    s3_migration_each_original do |file_set, original|
      identifier = original.file_identifier.to_s
      unless identifier.start_with?('shrine://')
        counts[:not_in_s3] += 1
        next false
      end

      begin
        s3_file = Valkyrie::StorageAdapter.find_by(id: original.file_identifier)
        md5 = s3_file.checksum(digests: [Digest::MD5.new]).first
        problems = []
        recorded_size = original.recorded_size.first
        problems << "size #{s3_file.size} != recorded #{recorded_size}" if recorded_size && s3_file.size.to_i != recorded_size.to_i
        stored = original.checksum.first.to_s
        problems << "md5 #{md5} != stored #{stored}" if stored.match?(/\A\h{32}\z/) && stored.downcase != md5
        if problems.empty?
          counts[:ok] += 1
        else
          puts "  PROBLEM #{file_set.id} - #{problems.join('; ')}"
          counts[:problems] += 1
        end
        true
      rescue StandardError => e
        puts "  PROBLEM #{file_set.id} - #{e.class}: #{e.message}"
        counts[:problems] += 1
        false
      end
    end

    puts "\nOK: #{counts[:ok]}  Problems: #{counts[:problems]}  Not yet in S3: #{counts[:not_in_s3]}"
  end
end
# rubocop:enable Metrics/BlockLength
