# frozen_string_literal: true

desc 'populate qa tables from the authority ymls (AUTHORITIES_PATH overrides config/authorities)'
task populate_qa: :environment do
  paths = ENV.fetch('AUTHORITIES_PATH', nil) || Qa::Authorities::Local.subauthorities_path

  Account.find_each do |account|
    next if account.search_only?

    puts "=============== #{account.name} ==============="
    Apartment::Tenant.switch(account.tenant) do
      LocalVocabularyService.seed!(paths).each do |name, count|
        puts "✓ #{name} (#{count} terms)"
      end
    end
  end
end
