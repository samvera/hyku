# frozen_string_literal: true

desc 'populate qa tables from the authority ymls (AUTHORITIES_PATH overrides config/authorities)'
task populate_qa: :environment do
  paths = ENV.fetch('AUTHORITIES_PATH', nil) || Qa::Authorities::Local.subauthorities_path

  # Ahead of the loop: raising mid-loop leaves the tenants after the bad file unseeded.
  invalid = LocalVocabularyService.invalid_files(paths)
  if invalid.any?
    abort "Rename these ymls before seeding. A vocabulary is named after its file, and the " \
          "name has to be lowercase letters, numbers, underscores and hyphens, starting with " \
          "a letter or number:\n#{invalid.map { |file| "  #{file}" }.join("\n")}"
  end

  Account.find_each do |account|
    next if account.search_only?

    puts "=============== #{account.name} ==============="
    Apartment::Tenant.switch(account.tenant) do
      LocalVocabularyService.seed!(paths).each do |name, count, seeded|
        puts seeded ? "✓ #{name} (#{count} terms)" : "· #{name} (already imported, #{count} terms)"
      end
    end
  end
end
