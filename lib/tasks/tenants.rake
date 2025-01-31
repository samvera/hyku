# frozen_string_literal: true

namespace :tenants do
  # How much space, works, files, per each tenant?
  task calculate_usage: :environment do
    @results = []
    Account.where(search_only: false).find_each do |account|
      next if account.cname.blank?

      AccountElevator.switch!(account.cname)
      puts "---------------#{account.cname}-------------------------"

      models = Hyrax.config.curation_concerns.map { |m| "\"#{m}\"" }
      works = ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", rows: 100_000)

      if works&.any?
        puts "#{works.count} works found"
        tenant_file_sizes = [] # Declare and initialize within the block

        works.each do |work|
          document = SolrDocument.find(work.id)
          files = document._source["file_set_ids_ssim"] || []

          if files.any?
            file_sizes = files.map do |file|
              f = SolrDocument.find(file.to_s)
              f.to_h['file_size_lts'] || 0
            rescue Blacklight::Exceptions::RecordNotFound => e
              puts "Warning: File #{file} not found. Skipping. Error: #{e.message}"
              0
            end

            total_file_size_bytes = file_sizes.inject(0, :+)
            tenant_file_sizes << (total_file_size_bytes / 1.0.megabyte).round(2)
          else
            tenant_file_sizes << 0
          end
        rescue Blacklight::Exceptions::RecordNotFound => e
          puts "Warning: Work #{work.id} not found. Skipping. Error: #{e.message}"
          tenant_file_sizes << 0
        end

        total_mb = tenant_file_sizes.inject(0, :+)
        @results << "#{account.cname}: #{total_mb} Total MB / #{works.count} Works"
      else
        @results << "#{account.cname}: 0 Total MB / 0 Works"
      end

      puts "=================================================================="
    end

    # Output results
    @results.each do |result|
      puts result
    end
  end
end
