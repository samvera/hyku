# frozen_string_literal: true

# Runs Hyrax's S3 migration tasks (hyrax:migrate:files_to_s3 and friends) once per tenant.
# Limit to some tenants with tenants="a.example.com b.example.com". See docs/migrating-files-to-s3.md.
namespace :hyku do
  namespace :s3_migration do
    %w[files_to_s3 verify_s3_files report_file_storage quarantine_disk_files rollback_s3_migration purge_quarantine].each do |name|
      desc "Run hyrax:migrate:#{name} in each tenant (tenants=\"a.example.com b.example.com\" to limit)"
      task name => :environment do
        hyrax_task = "hyrax:migrate:#{name}"
        abort "#{hyrax_task} is not defined; this needs a Hyrax release that includes it." unless Rake::Task.task_defined?(hyrax_task)

        on_error = ->(account, error) { puts "  TENANT ERROR #{account.cname} - #{error.class}: #{error.message}" }
        failed = Hyku::S3Migration::Tenants.each(tenants: ENV.fetch('tenants', '').split, on_error:) do |account|
          puts "=== Tenant: #{account.cname} ==="
          Rake::Task[hyrax_task].reenable
          Rake::Task[hyrax_task].invoke
        end
        puts "\nTenants that failed (rerun with tenants=\"<cname>\"): #{failed.join(', ')}" if failed.any?
      end
    end
  end
end
