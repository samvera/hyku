# rubocop:disable Metrics/LineLength
namespace :tenantize do
  desc 'Run given task on all or selected tenants'
  task :task, [:task_name] => :environment do |_cmd, args|
    raise ArgumentError, 'A rake task name is required: `rake tenantize:task[do:the:thing,arg1,...]`' if args.task_name.blank?
    raise ArgumentError, "Rake task not found: #{args.task_name}. Are you sure this task is defined?" unless Rake::Task.task_defined?(args.task_name)
    tenant_list = ENV.fetch('tenants', '').split
    Account.tenants(tenant_list).each do |account|
      puts "Running '#{args.task_name}' task within '#{account.cname}' tenant"
      account.switch do
        Rake::Task[args.task_name].invoke(*args.extras)
        # Re-enable the task or it won't be run the next iteration
        Rake::Task[args.task_name].reenable
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
