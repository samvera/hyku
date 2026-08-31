# frozen_string_literal: true

namespace :hyku do
  namespace :demo do
    desc 'Capture the golden snapshot (site appearance, content blocks, featured works) for a public demo tenant'
    task :snapshot, [:tenant] => :environment do |_task, args|
      raise ArgumentError, 'tenant (cname or name) is required, e.g. hyku:demo:snapshot[demo.example.org]' if args.tenant.blank?

      account = Account.find_by(cname: args.tenant) || Account.find_by(name: args.tenant)
      raise ArgumentError, "No account found for #{args.tenant}" unless account

      DemoTenantResetService.new(account:).snapshot!
      puts "Snapshot captured for #{account.cname}"
    end

    desc <<~DESC
      Reset a public demo tenant to its stored golden snapshot.

      Destroys visitor-created works, file sets, collections, and users;
      restores appearance settings and content blocks from the snapshot;
      optionally re-imports a seed corpus through Bulkrax; restores featured
      works; runs an injectable health check; stamps last_reset_at.

      Refuses to run for accounts not flagged public_demo_tenant. Capture a
      snapshot first with hyku:demo:snapshot.

      Options (environment variables):
        DEMO_SEED_CSV_PATH  absolute path to a Bulkrax CSV to re-import (optional)
        DEMO_KEEP_USERS     comma-separated emails that survive the reset in
                            addition to superadmins (optional)
        DEMO_IMPORT_USER    email of the user that owns the seed import
                            (optional, defaults to the first tenant admin)
        DEMO_HEALTH_CHECK   name of a class responding to .call(account) (optional)
    DESC
    task :reset, [:tenant] => :environment do |_task, args|
      raise ArgumentError, 'tenant (cname or name) is required, e.g. hyku:demo:reset[demo.example.org]' if args.tenant.blank?

      account = Account.find_by(cname: args.tenant) || Account.find_by(name: args.tenant)
      raise ArgumentError, "No account found for #{args.tenant}" unless account

      DemoTenantResetService.new(
        account:,
        seed_csv_path: ENV['DEMO_SEED_CSV_PATH'].presence,
        keep_emails: ENV.fetch('DEMO_KEEP_USERS', '').split(','),
        import_user_email: ENV['DEMO_IMPORT_USER'].presence,
        health_check: ENV['DEMO_HEALTH_CHECK'].presence&.constantize
      ).reset!
      puts "Reset completed for #{account.cname} (last_reset_at #{account.reload.last_reset_at})"
    end
  end
end
