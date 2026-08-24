# frozen_string_literal: true

namespace :perf do
  desc 'Create N dummy tenants with sample Valkyrie works, users, and admin sets, for tenant-count performance testing'
  task :seed_tenants, [:count, :quantity, :users_per_tenant, :admin_sets_per_tenant] => :environment do |_t, args|
    count = (args[:count] || 3).to_i
    quantity = (args[:quantity] || 10).to_i
    users_per_tenant = (args[:users_per_tenant] || 5).to_i
    admin_sets_per_tenant = (args[:admin_sets_per_tenant] || 2).to_i

    user = User.first
    raise 'No User exists to act as depositor - create one first (e.g. via db:seed).' unless user

    batch = SecureRandom.hex(3)
    password = SecureRandom.hex(12)
    created = []

    count.times do |i|
      # Rails.application.reloader.wrap keeps autoloaded constants fresh across
      # many tenant switches in one long-lived process - without it, a long
      # batch can hit spurious "uninitialized constant" NameErrors partway through.
      Rails.application.reloader.wrap do
        name = "perf-test-#{batch}-#{i}"
        puts "Creating tenant #{name}..."
        account = Account.new(name: name)

        if CreateAccount.new(account, [user]).save
          puts "  Created (cname: #{account.cname}). Seeding #{quantity} Valkyrie works..."
          Sample::ValkyrieService.new(account.name, quantity).create_sample_data

          # still switched into account's tenant here
          puts "  Adding #{users_per_tenant} users..."
          users_per_tenant.times do |j|
            new_user = User.create!(email: "perf-#{batch}-#{i}-#{j}@example.com", password: password, password_confirmation: password)
            new_user.add_role(:admin, Site.instance) if j.zero?
          end

          puts "  Adding #{admin_sets_per_tenant} extra admin sets..."
          admin_sets_per_tenant.times do |k|
            admin_set = Hyrax.config.admin_set_class.new(id: "perf-admin-set-#{batch}-#{i}-#{k}", title: "Extra Admin Set #{k}")
            Hyrax::AdminSetCreateService.call!(admin_set: admin_set, creating_user: user)
          end

          created << account
        else
          puts "  FAILED: #{account.errors.full_messages.join(', ')}"
        end
      rescue => e
        puts "  FAILED: #{e.message}"
      ensure
        begin
          Apartment::Tenant.switch!(nil)
        rescue => e
          puts "  WARNING: failed to reset tenant after iteration #{i}: #{e.message}"
        end
      end
    end

    puts "\nDone: #{created.length}/#{count} tenants created with #{quantity} works, #{users_per_tenant} users, #{admin_sets_per_tenant} extra admin sets each."
    created.each { |a| puts "  #{a.name} -> https://#{a.cname}" }
    puts "\nClean up with: bundle exec rake perf:destroy_tenants[#{batch}]" if created.any?
  end

  desc 'Destroy all tenants from a perf:seed_tenants batch (matches name prefix perf-test-<batch>)'
  task :destroy_tenants, [:batch] => :environment do |_t, args|
    raise 'Usage: bundle exec rake perf:destroy_tenants[batch]' if args[:batch].blank?

    accounts = Account.where("name LIKE ?", "perf-test-#{args[:batch]}-%")
    puts "Destroying #{accounts.count} tenant(s) matching batch #{args[:batch]}..."

    accounts.find_each do |account|
      puts "  Destroying #{account.name}..."
      CleanupAccountJob.perform_now(account)
    end

    users = User.where("email LIKE ?", "perf-#{args[:batch]}-%@example.com")
    puts "Destroying #{users.count} perf-test user(s)..."
    users.destroy_all

    puts "Done."
  end
end
