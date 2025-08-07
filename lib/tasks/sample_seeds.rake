# frozen_string_literal: true

namespace :db do
  namespace :seed do
    namespace :sample do
      desc 'Create sample works with file attachments for a specific tenant'
      task :create, [:tenant, :type, :quantity] => :environment do |_t, args|
        if args[:tenant].blank?
          puts "ERROR: Tenant name is required!"
          puts "Usage: bundle exec rake db:seed:sample:create[tenant_name,type,quantity]"
          puts "Examples:"
          puts "  bundle exec rake db:seed:sample:create[tenant_name,activefedora,100]"
          puts "  bundle exec rake db:seed:sample:create[tenant_name,valkyrie,50]"
          puts "  bundle exec rake db:seed:sample:create[tenant_name] (defaults: activefedora, 50)"
          puts "Types: 'activefedora' of 'af' (default) or 'valkyrie' or 'val'"
          exit 1
        end

        quantity = args[:quantity] || 50
        type = args[:type] || 'activefedora'

        case type.downcase
        when 'activefedora', 'af'
          Sample::ActiveFedoraService.new(args[:tenant], quantity).create_sample_data
        when 'valkyrie', 'val'
          Sample::ValkyrieService.new(args[:tenant], quantity).create_sample_data
        else
          puts "ERROR: Unknown type '#{type}'. Valid types are 'activefedora' or 'valkyrie'"
          exit 1
        end
      end

      desc 'Remove all sample data for a specific tenant'
      task :clean, [:tenant, :type] => :environment do |_t, args|
        if args[:tenant].blank?
          puts "ERROR: Tenant name is required!"
          puts "Usage: bundle exec rake db:seed:sample:clean[tenant_name,type]"
          puts "Examples:"
          puts "  bundle exec rake db:seed:sample:clean[myuniversity.edu,activefedora]"
          puts "  bundle exec rake db:seed:sample:clean[myuniversity.edu,valkyrie]"
          puts "  bundle exec rake db:seed:sample:clean[myuniversity.edu] (defaults to activefedora)"
          puts "Types: 'activefedora' (default) or 'valkyrie'"
          exit 1
        end

        type = args[:type] || 'activefedora'

        case type.downcase
        when 'activefedora', 'af'
          Sample::ActiveFedoraService.new(args[:tenant]).clean_sample_data
        when 'valkyrie', 'val'
          Sample::ValkyrieService.new(args[:tenant]).clean_sample_data
        else
          puts "ERROR: Unknown type '#{type}'. Valid types are 'activefedora' or 'valkyrie'"
          exit 1
        end
      end
    end
  end
end
