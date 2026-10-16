# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
namespace :hyku do
  def s3_migration_require_s3!
    abort 'Set REPOSITORY_S3_STORAGE=true (and the bucket variables) first.' unless Valkyrie::StorageAdapter.storage_adapters.key?(:repository_s3)
  end

  def s3_migration_client
    opts = { region: ENV.fetch('REPOSITORY_S3_REGION', 'us-east-1') }
    if ENV['REPOSITORY_S3_ACCESS_KEY'].present?
      opts[:access_key_id] = ENV['REPOSITORY_S3_ACCESS_KEY']
      opts[:secret_access_key] = ENV['REPOSITORY_S3_SECRET_KEY']
    end
    Aws::S3::Client.new(**opts)
  end

  def s3_migration_prefix
    '_migration-manifests/'
  end

  def s3_migration_each_tenant(tenant: ENV['TENANT'])
    accounts = tenant.present? ? Account.where(cname: tenant) : Account.all
    failed = []
    accounts.find_each do |account|
      next if account.name == 'search'

      AccountElevator.switch!(account.cname)
      puts "=== Tenant: #{account.cname} ==="
      yield account
    rescue StandardError => e
      puts "  TENANT ERROR #{account.cname} - #{e.class}: #{e.message}"
      failed << account.cname
    end
    puts "\nTenants that failed (rerun with TENANT=<cname>): #{failed.join(', ')}" if failed.any?
  end

  def s3_migration_each_original(limit: ENV['LIMIT']&.to_i, shard: ENV['SHARD'])
    shard_index, shard_count = shard.to_s.split('/').map(&:to_i) if shard.present?
    abort 'SHARD must look like 0/4 (zero-based index/count).' if shard && !(shard_count.to_i.positive? && (0...shard_count).cover?(shard_index))
    puts "[Shard #{shard_index}/#{shard_count}]" if shard

    s3_migration_each_tenant do |account|
      yielded = 0

      Hyrax.query_service.find_all_of_model(model: Hyrax::FileSet).each do |file_set|
        break if limit && yielded >= limit
        next if shard && Zlib.crc32(file_set.id.to_s) % shard_count != shard_index

        original = Hyrax.custom_queries.find_original_file(file_set:)
        next unless original

        yielded += 1 if yield(file_set, original, account)
      end
      Hyrax::SolrService.commit
    end
  end

  # Manifest lines are flushed to the bucket in immutable chunks, so a crashed run keeps what it finished.
  def s3_migration_manifest_writer(run_id)
    buffer = []
    seq = 0
    flush = lambda do
      next if buffer.empty?

      s3_migration_client.put_object(bucket: ENV.fetch('REPOSITORY_S3_BUCKET'), key: "#{s3_migration_prefix}#{run_id}/#{format('%06d', seq)}.jsonl", body: "#{buffer.join("\n")}\n")
      seq += 1
      buffer.clear
    end
    add = lambda do |entry|
      line = entry.to_json
      puts "  MANIFEST #{line}"
      buffer << line
      flush.call if buffer.size >= 100
    end
    [add, flush]
  end

  def s3_migration_each_manifest_entry(run: ENV['MANIFEST_RUN'])
    client = s3_migration_client
    bucket = ENV.fetch('REPOSITORY_S3_BUCKET')
    client.list_objects_v2(bucket:, prefix: "#{s3_migration_prefix}#{run}").each do |page|
      page.contents.each do |object|
        client.get_object(bucket:, key: object.key).body.read.each_line do |line|
          yield JSON.parse(line, symbolize_names: true)
        end
      end
    end
  end

  def s3_migration_disk_path(old_id, base)
    path = old_id.to_s.delete_prefix('disk://')
    path if path.start_with?("#{base}/")
  end

  desc <<~DESC
    Move disk-stored original files (disk:// identifiers) to the S3 repository
    storage adapter. Each upload is read back from S3 and its SHA-256 compared to the
    disk file before the identifier is switched; a mismatch deletes the upload and leaves
    the file on disk. Files whose disk copy does not match the stored characterization checksum
    are reported as SUSPECT and not migrated (dry runs report them too, but hash every file).
    Re-runnable (shrine:// files are skipped). Never deletes the disk copy. Every migrated file is
    recorded in a manifest under _migration-manifests/ in the bucket (and printed as MANIFEST lines).
    Env: DRY_RUN=true to preview, TENANT=<cname> for one tenant, LIMIT=<n> files per tenant,
    SHARD=<i>/<n> (zero-based, e.g. 0/4) to split the work across n concurrent processes.
  DESC
  task migrate_files_to_s3: :environment do
    s3_migration_require_s3!

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'false'))
    s3_storage = Valkyrie::StorageAdapter.find(:repository_s3)
    counts = Hash.new(0)
    run_id = "#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-#{ENV['SHARD'].to_s.tr('/', '_').presence || 'all'}"
    add_manifest, flush_manifest = s3_migration_manifest_writer(run_id)

    puts "[DRY RUN] No changes will be made.\n\n" if dry_run

    begin
      s3_migration_each_original do |file_set, original, account|
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
          add_manifest.call(tenant: account.cname, file_set_id: file_set.id.to_s, file_metadata_id: original.id.to_s,
                            old_id: identifier, new_id: uploaded.id.to_s, size: File.size(disk_path), sha256: disk_sha256,
                            at: Time.now.utc.iso8601)
          counts[:migrated] += 1
          true
        rescue StandardError => e
          puts "  ERROR #{file_set.id} - #{e.class}: #{e.message}"
          counts[:errors] += 1
          false
        end
      end
    ensure
      flush_manifest.call unless dry_run
    end

    puts "\nMigrated: #{counts[:migrated]}  Skipped: #{counts[:skipped]}  Suspect: #{counts[:suspect]}  Errors: #{counts[:errors]}"
    puts "Manifest run: #{run_id}" unless dry_run
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

  desc <<~DESC
    Read-only report of how much file storage is still on disk, per tenant, grouped by file
    use (original, thumbnail, extracted text, ...) and storage scheme. Anything still disk://
    after a migration (other than what you expect) must be understood before deleting from disk.
    Env: TENANT=<cname>.
  DESC
  task report_file_storage: :environment do
    totals = Hash.new { |h, k| h[k] = [0, 0] }

    s3_migration_each_tenant do
      Hyrax.query_service.find_all_of_model(model: Hyrax::FileSet).each do |file_set|
        Hyrax.custom_queries.find_files(file_set:).each do |file|
          use = Array(file.pcdm_use).map { |u| u.to_s.split('#').last }.join(',')
          scheme = file.file_identifier.to_s[/\A[a-z]+(?=:)/].to_s
          totals[[use, scheme]][0] += 1
          totals[[use, scheme]][1] += file.recorded_size.first.to_i
        end
      end
    end

    puts "\nuse | scheme | files | GB"
    totals.sort.each { |(use, scheme), (count, bytes)| puts "#{use} | #{scheme} | #{count} | #{(bytes / 1e9).round(2)}" }
  end

  desc <<~DESC
    Move the disk copies of manifest-listed files into <storage>/.quarantine (same volume, so
    it is a rename). Before moving each file it re-checks that the database still points at
    the S3 id and that the S3 object exists and matches the manifest size and SHA-256 (set
    VERIFY_SHA=false to skip the hash). Dry run unless APPLY=true.
    Env: MANIFEST_RUN=<run id prefix> (default: every run), APPLY=true.
  DESC
  task quarantine_migrated_disk_files: :environment do
    s3_migration_require_s3!
    apply = ActiveModel::Type::Boolean.new.cast(ENV.fetch('APPLY', 'false'))
    verify_sha = ActiveModel::Type::Boolean.new.cast(ENV.fetch('VERIFY_SHA', 'true'))
    base = Valkyrie::StorageAdapter.find(:disk).base_path.to_s
    s3_storage = Valkyrie::StorageAdapter.find(:repository_s3)
    counts = Hash.new(0)
    tenant = nil

    puts "[DRY RUN] Nothing will be moved. Set APPLY=true to move.\n\n" unless apply

    s3_migration_each_manifest_entry do |entry|
      AccountElevator.switch!(tenant = entry[:tenant]) unless tenant == entry[:tenant]
      path = s3_migration_disk_path(entry[:old_id], base)
      dest = path && File.join(base, '.quarantine', path.delete_prefix("#{base}/"))

      begin
        if path.nil?
          puts "  ERROR #{entry[:file_set_id]} - path outside #{base}: #{entry[:old_id]}"
          counts[:errors] += 1
        elsif !File.exist?(path)
          counts[File.exist?(dest) ? :already_quarantined : :disk_copy_missing] += 1
        elsif Hyrax.query_service.find_by(id: entry[:file_metadata_id]).file_identifier.to_s != entry[:new_id]
          puts "  SKIP  #{entry[:file_set_id]} - database no longer points at #{entry[:new_id]}"
          counts[:skipped] += 1
        else
          s3_file = s3_storage.find_by(id: entry[:new_id])
          if s3_file.size.to_i != entry[:size] || (verify_sha && s3_file.checksum(digests: [Digest::SHA256.new]).first != entry[:sha256])
            puts "  ERROR #{entry[:file_set_id]} - S3 object does not match manifest; disk copy kept"
            counts[:errors] += 1
          else
            puts "  #{'[DRY RUN] ' unless apply}Quarantine #{path}"
            if apply
              FileUtils.mkdir_p(File.dirname(dest))
              FileUtils.mv(path, dest)
              FileUtils.touch(dest)
            end
            counts[:quarantined] += 1
          end
        end
      rescue StandardError => e
        puts "  ERROR #{entry[:file_set_id]} - #{e.class}: #{e.message}"
        counts[:errors] += 1
      end
    end

    puts "\nQuarantined: #{counts[:quarantined]}  Already: #{counts[:already_quarantined]}  Disk copy missing: #{counts[:disk_copy_missing]}  Skipped: #{counts[:skipped]}  Errors: #{counts[:errors]}"
  end

  desc <<~DESC
    Permanently delete quarantined files older than MIN_AGE_DAYS (default 14). Dry run unless APPLY=true.
  DESC
  task purge_quarantine: :environment do
    apply = ActiveModel::Type::Boolean.new.cast(ENV.fetch('APPLY', 'false'))
    min_age = ENV.fetch('MIN_AGE_DAYS', '14').to_f.days
    dir = File.join(Valkyrie::StorageAdapter.find(:disk).base_path.to_s, '.quarantine')
    purged = kept = 0

    puts "[DRY RUN] Nothing will be deleted. Set APPLY=true to delete.\n\n" unless apply

    Dir.glob(File.join(dir, '**', '*')).select { |f| File.file?(f) }.each do |file|
      if Time.current - File.mtime(file) >= min_age
        File.delete(file) if apply
        purged += 1
      else
        kept += 1
      end
    end
    Dir.glob(File.join(dir, '**', '*', '')).sort.reverse_each { |d| Dir.rmdir(d) if Dir.empty?(d) } if apply

    puts "#{apply ? 'Deleted' : 'Would delete'}: #{purged}  Too recent: #{kept}"
  end

  desc <<~DESC
    Undo a migration from the manifest: restore the disk copy (from quarantine if needed) and
    point the file back at its original disk:// id. The S3 object is left in place.
    Dry run unless APPLY=true. Env: MANIFEST_RUN=<run id prefix> (default: every run).
  DESC
  task rollback_migrated_files: :environment do
    s3_migration_require_s3!
    apply = ActiveModel::Type::Boolean.new.cast(ENV.fetch('APPLY', 'false'))
    base = Valkyrie::StorageAdapter.find(:disk).base_path.to_s
    counts = Hash.new(0)
    tenant = nil

    puts "[DRY RUN] Nothing will change. Set APPLY=true to roll back.\n\n" unless apply

    s3_migration_each_manifest_entry do |entry|
      AccountElevator.switch!(tenant = entry[:tenant]) unless tenant == entry[:tenant]
      path = s3_migration_disk_path(entry[:old_id], base)
      dest = path && File.join(base, '.quarantine', path.delete_prefix("#{base}/"))

      begin
        current = Hyrax.query_service.find_by(id: entry[:file_metadata_id])
        if path.nil? || current.file_identifier.to_s != entry[:new_id]
          counts[:skipped] += 1
        elsif !File.exist?(path) && !File.exist?(dest)
          puts "  ERROR #{entry[:file_set_id]} - disk copy is gone; cannot roll back"
          counts[:errors] += 1
        else
          puts "  #{'[DRY RUN] ' unless apply}Rolling back #{entry[:file_set_id]}"
          if apply
            unless File.exist?(path)
              FileUtils.mkdir_p(File.dirname(path))
              FileUtils.mv(dest, path)
            end
            current.file_identifier = Valkyrie::ID.new(entry[:old_id])
            Hyrax.persister.save(resource: current)
            Hyrax.index_adapter.save(resource: Hyrax.query_service.find_by(id: entry[:file_set_id]))
          end
          counts[:rolled_back] += 1
        end
      rescue StandardError => e
        puts "  ERROR #{entry[:file_set_id]} - #{e.class}: #{e.message}"
        counts[:errors] += 1
      end
    end

    puts "\nRolled back: #{counts[:rolled_back]}  Skipped: #{counts[:skipped]}  Errors: #{counts[:errors]}"
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
