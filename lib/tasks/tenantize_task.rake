# frozen_string_literal: true

# rubocop:disable Layout/LineLength
namespace :tenantize do
  desc 'Run given task on all or selected tenants'
  task :task, [:task_name] => :environment do |_cmd, args|
    raise ArgumentError, 'A rake task name is required: `rake tenantize:task[do:the:thing,arg1,...]`' if args.task_name.blank?
    raise ArgumentError, "Rake task not found: #{args.task_name}. Are you sure this task is defined?" unless Rake::Task.task_defined?(args.task_name)
    tenant_list = ENV.fetch('tenants', '').split
    # Search-only accounts have no repository of their own; their index aggregates other tenants.
    Account.tenants(tenant_list).reject(&:search_only?).each do |account|
      puts "Running '#{args.task_name}' task within '#{account.cname}' tenant"
      Apartment::Tenant.switch(account.tenant) do
        # Rake runs a task only once per process unless it is re-enabled.
        Rake::Task[args.task_name].reenable
        Rake::Task[args.task_name].invoke(*args.extras)
      end
    end
  end
end
# rubocop:enable Layout/LineLength
