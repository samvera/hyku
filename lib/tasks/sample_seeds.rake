# frozen_string_literal: true

namespace :db do
  namespace :seed do
    namespace :sample do
      desc 'Create sample works with file attachments for a specific tenant'
      task :create, [:tenant, :type, :quantity, :visibility] => :environment do |_t, args|
        if args[:tenant].blank?
          puts "ERROR: Tenant name is required!"
          puts "Usage: bundle exec rake db:seed:sample:create[tenant_name,type,quantity,visibility]"
          puts "Examples:"
          puts "  bundle exec rake db:seed:sample:create[tenant_name,activefedora,100]"
          puts "  bundle exec rake db:seed:sample:create[tenant_name,valkyrie,50,open]"
          puts "  bundle exec rake db:seed:sample:create[tenant_name,valkyrie,'generic_work:5;image:2',open]"
          puts "  bundle exec rake db:seed:sample:create[tenant_name] (defaults: activefedora, 50)"
          puts "Types: 'activefedora' of 'af' (default) or 'valkyrie' or 'val'"
          puts "Quantity: a number, applied to every work type the tenant offers and to"
          puts "          collections, or per-type counts as 'work_type:count' pairs"
          puts "          separated by ';' (works only; one collection is created)"
          puts "Visibility: 'open', 'authenticated' or 'restricted' (optional)"
          exit 1
        end

        quantity_arg = args[:quantity] || 50
        type = args[:type] || 'activefedora'
        visibility = args[:visibility]&.downcase

        valid_visibilities = Hyrax::VisibilityMap.instance.visibilities
        if visibility && !valid_visibilities.include?(visibility)
          puts "ERROR: Unknown visibility '#{visibility}'. Valid values are #{valid_visibilities.map { |v| "'#{v}'" }.join(', ')}"
          exit 1
        end

        # Either a bare number, or 'work_type:count' pairs. Semicolons because
        # rake already claims the comma. Per-type counts cover works only, so
        # quantity still governs collections; default to one so seeded works
        # have somewhere to live.
        work_types = nil
        quantity = quantity_arg
        if quantity_arg.to_s.include?(':')
          work_types = quantity_arg.to_s.split(';').to_h do |pair|
            name, count = pair.split(':', 2)
            [name.to_s.strip, count.to_i]
          end
          quantity = 1
        end

        service_class = case type.downcase
                        when 'activefedora', 'af' then Sample::ActiveFedoraService
                        when 'valkyrie', 'val' then Sample::ValkyrieService
                        end

        if service_class.nil?
          puts "ERROR: Unknown type '#{type}'. Valid types are 'activefedora' or 'valkyrie'"
          exit 1
        end

        begin
          service_class.new(args[:tenant], quantity, visibility, work_types:).create_sample_data
        rescue ArgumentError => e
          puts "ERROR: #{e.message}"
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
