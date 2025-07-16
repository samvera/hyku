# frozen_string_literal: true

namespace :hyrax do
  namespace :controlled_vocabularies do
    desc "Populate the database with the default set of controlled vocabularies for a specific tenant, or for all tenants if no name is provided."
    task :populate, [:name] => :environment do |_task, args|
      def seed_vocabularies_for_tenant(account)
        Apartment::Tenant.switch!(account.tenant) do
          puts "Seeding Controlled Vocabularies for tenant: #{account.name}"

          # Local Vocabularies
          local_vocabularies = {
            'audience' => 'Hyrax::AudienceService',
            'discipline' => 'Hyrax::DisciplineService',
            'education_levels' => 'Hyrax::EducationLevelsService',
            'learning_resource_types' => 'Hyrax::LearningResourceTypesService',
            'oer_types' => 'Hyrax::OerTypesService',
            'licenses' => 'Hyrax::LicenseService',
            'resource_types' => 'Hyrax::ResourceTypesService',
            'rights_statements' => 'Hyrax::RightsStatementService'
          }

          local_vocabularies.each do |name, service_class|
            ControlledVocabulary.find_or_create_by!(name: name) do |vocab|
              vocab.vocabulary_type = 'local'
              vocab.service_class = service_class
            end
          end

          # Remote Authorities
          remote_authorities = {
            'loc/subjects' => { url: "/authorities/search/loc/subjects", type: 'autocomplete' },
            'loc/names' => { url: "/authorities/search/loc/names", type: 'autocomplete' },
            'loc/genre_forms' => { url: "/authorities/search/loc/genreForms", type: 'autocomplete' },
            'loc/countries' => { url: "/authorities/search/loc/countries", type: 'autocomplete' },
            'getty/aat' => { url: "/authorities/search/getty/aat", type: 'autocomplete' },
            'getty/tgn' => { url: "/authorities/search/getty/tgn", type: 'autocomplete' },
            'getty/ulan' => { url: "/authorities/search/getty/ulan", type: 'autocomplete' },
            'geonames' => { url: "/authorities/search/geonames", type: 'autocomplete' },
            'fast' => { url: "/authorities/search/assign_fast/topical", type: 'autocomplete' },
            'fast/all' => { url: "/authorities/search/assign_fast/all", type: 'autocomplete' },
            'fast/personal' => { url: "/authorities/search/assign_fast/personal", type: 'autocomplete' },
            'fast/corporate' => { url: "/authorities/search/assign_fast/corporate", type: 'autocomplete' },
            'fast/geographic' => { url: "/authorities/search/assign_fast/geographic", type: 'autocomplete' },
            'mesh' => { url: "/authorities/search/mesh", type: 'autocomplete' },
            'discogs' => { url: "/authorities/search/discogs/all", type: 'autocomplete' },
            'discogs/release' => { url: "/authorities/search/discogs/release", type: 'autocomplete' },
            'discogs/master' => { url: "/authorities/search/discogs/master", type: 'autocomplete' }
          }

          remote_authorities.each do |name, config|
            ControlledVocabulary.find_or_create_by!(name: name) do |vocab|
              vocab.vocabulary_type = 'remote'
              vocab.configuration = config
            end
          end
          puts "Controlled Vocabularies seeded for tenant: #{account.name}."
        end
      end

      if args[:name].present?
        account = Account.find_by(name: args[:name])
        if account.nil?
          puts "ERROR: Tenant with name '#{args[:name]}' not found."
          exit 1
        end
        seed_vocabularies_for_tenant(account)
      else
        puts "No tenant name provided. Seeding for all tenants."
        Account.find_each do |account|
          seed_vocabularies_for_tenant(account)
        end
      end
    end
  end
end
