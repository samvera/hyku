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
      works = Hyrax::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", rows: 100_000, fl: 'id,member_ids_ssim')

      puts "#{works.count} works found"
      total_mbs = [] # Declare and initialize within the block
      works.each do |work|
        member_ids = work.fetch("member_ids_ssim", [])
        next if member_ids.blank?

        file_sets = Hyrax::SolrService.query("id:(#{member_ids.join(' OR ')}) AND has_model_ssim:FileSet", rows: 100_000, fl: 'id,file_size_lts')
        next if file_sets.blank?

        total_file_size_bytes =
          file_sets.inject(0) do |sum, file_set|
            file_set['file_size_lts'].to_i + sum
          end

        total_mbs << (total_file_size_bytes / 1.0.megabyte).round(2)
      end

      @results << "#{account.cname}: #{total_mbs.sum} Total MB / #{works.count} Works"

      puts "=================================================================="
    end

    # Output results
    @results.each do |result|
      puts result
    end
  end
end
