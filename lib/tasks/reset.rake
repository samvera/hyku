# frozen_string_literal: true

namespace :reset do
  desc 'reset work and collection data across all tenants'
  task all_works_and_collections: [:environment] do
    confirm('You are about to delete all works and collections across all accounts, this is not reversable!')
    Account.find_each do |account|
      switch!(account)
      Rake::Task["hyrax:reset:works_and_collections"].reenable
      Rake::Task["hyrax:reset:works_and_collections"].invoke
    end
  end

  desc 'reset work and collection data from a single tenant, any argument that works with switch!() will work here'
  task :works_and_collections, [:account] => [:environment] do |_t, args|
    raise "You must speficy a name, cname or id of an account" if args[:account].blank?

    confirm("You are about to delete all works and collections from #{args[:account]}, this is not reversable!")
    switch!(args[:account])
    Rake::Task["hyrax:reset:works_and_collections"].reenable
    Rake::Task["hyrax:reset:works_and_collections"].invoke
  end

  def confirm(action)
    return if ENV['RESET_CONFIRMED'].present?
    confirm_token = rand(36**6).to_s(36)
    STDOUT.puts "#{action} Enter '#{confirm_token}' to confirm:"
    input = STDIN.gets.chomp
    raise "Aborting. You entered #{input}" unless input == confirm_token
    ENV['RESET_CONFIRMED'] = 'true'
  end
end
