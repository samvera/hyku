# frozen_string_literal: true

namespace :tenants do
  # how much space, works, files, per each tenant?
  task calculate_usage: :environment do
    @results = []
    Account.where(search_only: false).find_each do |account|
      if account.cname.present?
        AccountElevator.switch!(account.cname)
        puts "---------------#{account.cname}-------------------------"
        models = Hyrax.config.curation_concerns.map { |m| "\"#{m}\"" }
        works = ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", rows: 100_000)
        if works&.any?
          puts "#{works.count} works found"
          @tenant_file_sizes = []
          works.each do |work|
            document = SolrDocument.find(work.id)
            files = document._source["file_set_ids_ssim"]
            if files&.any?
              file_sizes = []
              files.each do |file|
                f = SolrDocument.find(file.to_s)
                if file
                  file_sizes.push(f.to_h['file_size_lts']) unless f.to_h['file_size_lts'].nil?
                else
                  files_sizes.push(0)
                 end
              end
              if file_sizes.any?
                file_sizes_total_bytes = file_sizes.inject(0, :+)
                file_size_total = (file_sizes_total_bytes / 1.0.megabyte).round(2)
              else
                file_size_total = 0
              end
              @tenant_file_sizes.push(file_size_total)
            else
              @tenant_file_sizes.push(0)
            end
          end
          if @tenant_file_sizes
            tenant_file_sizes_total_megabytes = @tenant_file_sizes.inject(0, :+)
            @results.push("#{account.cname}: #{tenant_file_sizes_total_megabytes} Total MB / #{works.count} Works")
          else
            @results.push("#{account.cname}: 0 Total MB / #{works.count} Works")
          end
        else
          @results.push("#{account.cname}: 0 Total MB / 0 Works")
        end
        puts "=================================================================="
        @results.each do |result|
          puts result
        end
      end
    end
  end
end
