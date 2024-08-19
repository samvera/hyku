# frozen_string_literal: true
namespace :counter_metrics do
  # bundle exec rake counter_metrics:import_investigations['pittir.hykucommons.org','spec/fixtures/csv/pittir-views.csv']
  desc 'import historical counter requests'
  task 'import_requests', [:tenant_cname, :csv_path] => [:environment] do |_cmd, args|
    raise ArgumentError, 'A tenant cname is required: `rake counter_metrics:import_requests[tenant_cname]`' if args.tenant_cname.blank?
    raise ArgumentError, "Tenant not found: #{args.tenant_cname}. Are you sure this is the correct tenant cname?" unless Account.where(cname: args.tenant_cname).first
    AccountElevator.switch!(args.tenant_cname)
    puts "Importing historical requests for #{args.tenant_cname}"
    ImportCounterMetrics.import_requests(args.csv_path)
  end

  # bundle exec rake counter_metrics:import_requests['pittir.hykucommons.org','spec/fixtures/csv/pittir-downloads.csv']
  desc 'import historical counter investigations'
  task 'import_investigations', [:tenant_cname, :csv_path] => [:environment] do |_cmd, args|
    raise ArgumentError, 'A tenant cname is required: `rake counter_metrics:import_investigations[tenant_cname]`' if args.tenant_cname.blank?
    raise ArgumentError, "Tenant not found: #{args.tenant_cname}. Are you sure this is the correct tenant cname?" unless Account.where(cname: args.tenant_cname).first
    AccountElevator.switch!(args.tenant_cname)
    puts "Importing historical investigations for #{args.tenant_cname}"
    ImportCounterMetrics.import_investigations(args.csv_path)
  end

  # You can optionally pass work IDs to have hyrax counter metrics created for specific works.
  # Or, you can pass a limit for the number of CounterMetric entries you would like to create. currently they are randomly created.
  #
  # Example for pitt tenant in dev without ids:
  # bundle exec rake counter_metrics:generate_staging_metrics[pitt.hyku.test]
  #
  # Example with ids:
  # bundle exec rake "counter_metrics:generate_staging_metrics[pitt.hyku.test, ab3c1f9d-684a-4c14-93b1-75586ec05f7a|891u493hdfhiu939]"
  #
  # Example with limit of 1:
  # bundle exec rake "counter_metrics:generate_staging_metrics[pitt.hyku.test, , 1]"
  #
  # NOTE: this should never be run in prod.
  # It generates fake data, so running in prod would risk contaminating prod data.
  desc 'generate counter metric test data for staging'
  task 'generate_staging_metrics', [:tenant_cname, :ids, :limit] => [:environment] do |_cmd, args|
    raise ArgumentError, 'A tenant cname is required: `rake counter_metrics:generate_staging_metrics[tenant_cname]`' if args.tenant_cname.blank?
    kwargs = {}
    kwargs[:ids] = args.ids.split("|") if args.ids.present?
    kwargs[:limit] = Integer(args.limit) if args.limit.present?
    AccountElevator.switch!(args.tenant_cname)
    puts "Creating test counter metric data for #{args.tenant_cname}"
    GenerateCounterMetrics.generate_counter_metrics(**kwargs)
    puts 'Test data created successfully'
  end
end
