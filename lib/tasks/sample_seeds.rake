# frozen_string_literal: true

namespace :db do
  namespace :seed do
    namespace :sample do
      desc 'Create sample Active Fedora works with file attachments for a specific tenant'
      task :create, [:tenant, :quantity] => :environment do |t, args|
        if args[:tenant].blank?
          puts "ERROR: Tenant name is required!"
          puts "Usage: bundle exec rake db:seed:sample:create[tenant_name,quantity]"
          puts "Example: bundle exec rake db:seed:sample:create[myuniversity.edu,100]"
          puts "Example: bundle exec rake db:seed:sample:create[myuniversity.edu] (defaults to 50)"
          exit 1
        end

        quantity = args[:quantity] || 50
        Sample::ActiveFedoraService.new(args[:tenant], quantity).create_sample_data
      end

      desc 'Remove all sample data for a specific tenant'
      task :clean, [:tenant] => :environment do |t, args|
        if args[:tenant].blank?
          puts "ERROR: Tenant name is required!"
          puts "Usage: bundle exec rake db:seed:sample:clean[tenant_name]"
          puts "Example: bundle exec rake db:seed:sample:clean[myuniversity.edu]"
          exit 1
        end

        Sample::ActiveFedoraService.new(args[:tenant]).clean_sample_data
      end
    end
  end
end
