# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :hyku do
  def s3_migration_each_original(tenant: ENV['TENANT'], limit: ENV['LIMIT']&.to_i, shard: ENV['SHARD'])
    shard_index, shard_count = shard.to_s.split('/').map(&:to_i) if shard.present?
    abort 'SHARD must look like 0/4 (zero-based index/count).' if shard && !(shard_count.to_i.positive? && (0...shard_count).cover?(shard_index))
    puts "[Shard #{shard_index}/#{shard_count}]" if shard

    accounts = tenant.present? ? Account.where(cname: tenant) : Account.all
    accounts.find_each do |account|
      AccountElevator.switch!(account.cname)
      puts "=== Tenant: #{account.cname} ==="
      yielded = 0

      Hyrax.query_service.find_all_of_model(model: Hyrax::FileSet).each do |file_set|
        break if limit && yielded >= limit
        next if shard && Zlib.crc32(file_set.id.to_s) % shard_count != shard_index

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
    the file on disk. Files whose disk copy does not match the stored characterization checksum
    are reported as SUSPECT and not migrated (dry runs report them too, but hash every file). Re-runnable (shrine:// files are skipped). Never deletes the disk copy.
    Env: DRY_RUN=true to preview, TENANT=<cname> for one tenant, LIMIT=<n> files per tenant,
    SHARD=<i>/<n> (zero-based, e.g. 0/4) to split the work across n concurrent processes.
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

      stored = original.checksum.first.to_s.downcase.delete_prefix('urn:sha1:').delete_prefix('urn:md5:')
      algorithm = { 32 => Digest::MD5, 40 => Digest::SHA1 }[stored.length] if stored.match?(/\A\h+\z/)
      if algorithm && algorithm.file(disk_path).hexdigest != stored
        puts "  SUSPECT #{file_set.id} - disk file does not match stored checksum #{stored}; not migrated"
        counts[:suspect] += 1
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

        current = Hyrax.query_service.find_by(id: original.id)
        unless current.file_identifier.to_s.start_with?('disk://')
          s3_storage.delete(id: uploaded.id)
          puts "  SKIP  #{file_set.id} - already migrated by another process; upload removed"
          counts[:skipped] += 1
          next false
        end

        current.file_identifier = uploaded.id
        Hyrax.persister.save(resource: current)
        Hyrax.index_adapter.save(resource: file_set)
        counts[:migrated] += 1
        true
      rescue StandardError => e
        puts "  ERROR #{file_set.id} - #{e.class}: #{e.message}"
        counts[:errors] += 1
        false
      end
    end

    puts "\nMigrated: #{counts[:migrated]}  Skipped: #{counts[:skipped]}  Suspect: #{counts[:suspect]}  Errors: #{counts[:errors]}"
  end

  desc <<~DESC
    Read-only audit of originals already in S3 (shrine://): the object must exist, match the
    recorded size, and match the stored MD5 checksum where one is present. Run it and get zero
    problems before deleting anything from disk.
    Env: TENANT=<cname> for one tenant, LIMIT=<n> files per tenant, SHARD=<i>/<n> as above.
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
