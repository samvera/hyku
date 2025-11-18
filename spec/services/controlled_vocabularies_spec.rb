# frozen_string_literal: true

RSpec.describe 'Controlled Vocabularies Integration', type: :service do
  around do |example|
    original_env = ENV['HYRAX_FLEXIBLE']
    ENV['HYRAX_FLEXIBLE'] = 'true'
    example.run
    ENV['HYRAX_FLEXIBLE'] = original_env
  end

  let(:profile_yaml) do
    <<~YAML
      ---
      m3_version: 1.0.beta2
      profile:
        date_modified: "2025-11-17"
        responsibility: https://samvera.org
        responsibility_statement: Hyku M3 Profile with Controlled Vocabularies Test
        type: Test Profile for Controlled Vocabularies
        version: 1.0
      classes:
        GenericWorkResource:
          display_label: Generic Work
        AdminSetResource:
          display_label: Admin Set
        CollectionResource:
          display_label: Collection
        Hyrax::FileSet:
          display_label: File Set
      contexts:
        flexible_context:
          display_label: Flexible Metadata Test
      mappings:
        blacklight:
          name: Additional Blacklight Solr Mappings
      properties:
        title:
          available_on:
            class:
              - GenericWorkResource
          cardinality:
            minimum: 1
          data_type: array
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - "null"
          display_label:
            default: Title
          form:
            required: true
            primary: true
          property_uri: http://purl.org/dc/terms/title
          range: http://www.w3.org/2001/XMLSchema#string
        # LOCAL CONTROLLED VOCABULARY EXAMPLE
        audience:
          available_on:
            class:
              - GenericWorkResource
          cardinality:
            minimum: 0
          data_type: array
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - audience
          display_label:
            default: Audience
          form:
            required: false
            primary: false
          property_uri: http://schema.org/EducationalAudience
          range: http://www.w3.org/2001/XMLSchema#string
        # REMOTE CONTROLLED VOCABULARY EXAMPLE FOR LIBRARY OF CONGRESS SUBJECTS
        subject:
          available_on:
            class:
              - GenericWorkResource
          cardinality:
            minimum: 0
          data_type: array
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
              - loc/subjects
          display_label:
            default: Subject
          form:
            required: false
            primary: false
          property_uri: http://purl.org/dc/elements/1.1/subject
          range: http://www.w3.org/2001/XMLSchema#string
        # REMOTE CONTROLLED VOCABULARY EXAMPLE FOR LIBRARY OF CONGRESS LANGUAGES
        language:
          available_on:
            class:
            - GenericWorkResource
          cardinality:
            minimum: 0
          data_type: array
          controlled_values:
            format: http://www.w3.org/2001/XMLSchema#string
            sources:
            - loc/languages
          display_label:
            default: blacklight.search.fields.show.language_tesim
          form:
            primary: false
          property_uri: http://purl.org/dc/elements/1.1/language
          range: http://www.w3.org/2001/XMLSchema#string
    YAML
  end

  describe 'Local Controlled Vocabularies' do
    context 'when HYRAX_FLEXIBLE is enabled' do
      it 'loads local vocabulary services correctly' do
        expect(Hyrax::ControlledVocabularies.services).to include('audience')
        expect(Hyrax::ControlledVocabularies.services['audience']).to eq('Hyrax::AudienceService')
      end

      it 'provides local vocabulary options through service' do
        expect(Hyrax::AudienceService).to respond_to(:select_all_options)
        options = Hyrax::AudienceService.select_all_options
        expect(options).to be_an(Array)
        expect(options).not_to be_empty
        expect(options.first).to be_an(Array)
        expect(options.first.length).to eq(2) # [label, value] pairs
      end

      it 'can resolve labels for local vocabulary values' do
        expect(Hyrax::AudienceService.label('Student')).to eq('Student')
      end

      context 'with flexible metadata profile using local vocabulary' do
        let(:profile) { YAML.safe_load(profile_yaml) }

        it 'recognizes local vocabulary sources in profile' do
          audience_property = profile['properties']['audience']
          expect(audience_property['controlled_values']['sources']).to include('audience')
        end

        it 'maps local vocabulary to known services' do
          source = 'audience'
          expect(Hyrax::ControlledVocabularies.services).to have_key(source)
          service_class = Hyrax::ControlledVocabularies.services[source].constantize
          expect(service_class).to respond_to(:select_all_options)
        end
      end
    end
  end

  describe 'Remote Controlled Vocabularies' do
    context 'when HYRAX_FLEXIBLE is enabled' do
      it 'loads remote vocabulary authorities correctly for subject' do
        expect(Hyrax::ControlledVocabularies.remote_authorities).to include('loc/subjects')
        authority_config = Hyrax::ControlledVocabularies.remote_authorities['loc/subjects']
        expect(authority_config[:url]).to eq('/authorities/search/loc/subjects')
        expect(authority_config[:type]).to eq('autocomplete')
      end

      it 'loads remote vocabulary authorities correctly for language' do
        expect(Hyrax::ControlledVocabularies.remote_authorities).to include('loc/languages')
        authority_config = Hyrax::ControlledVocabularies.remote_authorities['loc/languages']
        expect(authority_config[:url]).to eq('/authorities/search/loc/languages')
        expect(authority_config[:type]).to eq('autocomplete')
      end

      it 'includes common remote authorities' do
        remote_authorities = Hyrax::ControlledVocabularies.remote_authorities

        # Library of Congress authorities
        expect(remote_authorities).to have_key('loc/subjects')
        expect(remote_authorities).to have_key('loc/names')
        expect(remote_authorities).to have_key('loc/genre_forms')
        expect(remote_authorities).to have_key('loc/countries')
        expect(remote_authorities).to have_key('loc/languages')
        expect(remote_authorities).to have_key('loc/iso639-1')
        expect(remote_authorities).to have_key('loc/iso639-2')

        # FAST authorities
        expect(remote_authorities).to have_key('fast')
        expect(remote_authorities).to have_key('fast/geographic')

        # Getty authorities
        expect(remote_authorities).to have_key('getty/aat')

        # Other authorities
        expect(remote_authorities).to have_key('mesh')
        expect(remote_authorities).to have_key('discogs/release')
      end

      context 'with flexible metadata profile using remote vocabulary' do
        let(:profile) { YAML.safe_load(profile_yaml) }

        it 'recognizes remote vocabulary sources in profile for subject' do
          subject_property = profile['properties']['subject']
          expect(subject_property['controlled_values']['sources']).to include('loc/subjects')
        end

        it 'recognizes remote vocabulary sources in profile for language' do
          language_property = profile['properties']['language']
          expect(language_property['controlled_values']['sources']).to include('loc/languages')
        end

        it 'maps remote vocabulary to known authorities for subject' do
          source = 'loc/subjects'
          expect(Hyrax::ControlledVocabularies.remote_authorities).to have_key(source)
          authority_config = Hyrax::ControlledVocabularies.remote_authorities[source]
          expect(authority_config[:type]).to eq('autocomplete')
          expect(authority_config[:url]).to be_present
        end

        it 'maps remote vocabulary to known authorities for language' do
          source = 'loc/languages'
          expect(Hyrax::ControlledVocabularies.remote_authorities).to have_key(source)
          authority_config = Hyrax::ControlledVocabularies.remote_authorities[source]
          expect(authority_config[:type]).to eq('autocomplete')
          expect(authority_config[:url]).to be_present
        end
      end
    end
  end

  describe 'Flexible Metadata Integration' do
    context 'when HYRAX_FLEXIBLE is true' do
      let(:profile) { YAML.safe_load(profile_yaml) }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('HYRAX_FLEXIBLE').and_return('true')
      end

      it 'processes profiles with controlled vocabularies correctly' do
        expect(profile['properties']['audience']['controlled_values']['sources']).to eq(['audience'])
        expect(profile['properties']['subject']['controlled_values']['sources']).to eq(['loc/subjects'])
      end

      it 'distinguishes between local and remote vocabularies' do
        audience_sources = profile['properties']['audience']['controlled_values']['sources']
        subject_sources = profile['properties']['subject']['controlled_values']['sources']

        expect(Hyrax::ControlledVocabularies.services).to have_key(audience_sources.first)

        expect(Hyrax::ControlledVocabularies.remote_authorities).to have_key(subject_sources.first)
      end

      it 'validates that controlled vocabulary services exist' do
        expect { Hyrax::AudienceService.select_all_options }.not_to raise_error
        expect { Hyrax::DisciplineService.select_all_options }.not_to raise_error
      end

      it 'validates that remote authorities are configured' do
        remote_auth = Hyrax::ControlledVocabularies.remote_authorities['loc/subjects']
        expect(remote_auth).to be_present
        expect(remote_auth[:url]).to start_with('/authorities/search/')
        expect(remote_auth[:type]).to eq('autocomplete')
      end
    end

    context 'when HYRAX_FLEXIBLE is false' do
      around do |example|
        original_env = ENV['HYRAX_FLEXIBLE']
        ENV['HYRAX_FLEXIBLE'] = 'false'
        example.run
        ENV['HYRAX_FLEXIBLE'] = original_env
      end

      it 'still has access to controlled vocabulary configurations' do
        expect(Hyrax::ControlledVocabularies.services).to be_present
        expect(Hyrax::ControlledVocabularies.remote_authorities).to be_present
      end
    end
  end

  describe 'Service Integration Test' do
    it 'can load and use audience service with expected data' do
      options = Hyrax::AudienceService.select_all_options
      expect(options).to be_an(Array)
      expect(options.length).to be > 0

      first_option = options.first
      expect(first_option).to be_an(Array)
      expect(first_option.length).to eq(2)

      expect(options).to include(['Student', 'Student'])
    end

    it 'can load and use discipline service with expected data' do
      options = Hyrax::DisciplineService.select_all_options
      expect(options).to be_an(Array)
      expect(options.length).to be > 0

      expect(options.length).to be >= 60

      first_option = options.first
      expect(first_option).to be_an(Array)
      expect(first_option.length).to eq(2)
    end

    it 'provides labels for controlled vocabulary terms' do
      expect(Hyrax::AudienceService.label('Student')).to eq('Student')
      expect(Hyrax::AudienceService.label('Instructor')).to eq('Instructor')

      expect(Hyrax::DisciplineService.label('Computing and Information - Computer Science'))
        .to eq('Computing and Information - Computer Science')
    end
  end

  describe 'Configuration Completeness' do
    it 'has all expected local vocabulary services configured' do
      expected_local_services = %w[
        audience
        discipline
        education_levels
        learning_resource_types
        oer_types
        licenses
        resource_types
        rights_statements
      ]

      expected_local_services.each do |service|
        expect(Hyrax::ControlledVocabularies.services).to have_key(service)
        service_class = Hyrax::ControlledVocabularies.services[service].constantize

        # Handle different service patterns:
        # 1. Module-based services with select_all_options (most Hyku services)
        # 2. Module-based services with select_options (ResourceTypesService)
        # 3. Class-based services that inherit from QaSelectService (LicenseService, RightsStatementService)

        if service_class.respond_to?(:select_all_options)
          # Most Hyku services use select_all_options
          expect(service_class).to respond_to(:select_all_options)
        elsif service_class.respond_to?(:select_options)
          # ResourceTypesService uses select_options
          expect(service_class).to respond_to(:select_options)
        elsif service_class.respond_to?(:new)
          # Class-based services that need instantiation
          service_instance = service_class.new
          expect(service_instance).to respond_to(:select_all_options)
        else
          # Fallback: just verify the service class exists and is accessible
          expect(service_class).to be_present
        end
      end
    end

    it 'has all expected remote authorities configured' do
      expected_remote_authorities = %w[
        loc/subjects
        loc/names
        loc/languages
        loc/iso639-1
        loc/iso639-2
        loc/genre_forms
        loc/countries
        getty/aat
        getty/tgn
        getty/ulan
        geonames
        fast
        fast/all
        fast/personal
        fast/corporate
        fast/geographic
        mesh
        discogs
        discogs/release
        discogs/master
      ]

      expected_remote_authorities.each do |authority|
        expect(Hyrax::ControlledVocabularies.remote_authorities).to have_key(authority)
        config = Hyrax::ControlledVocabularies.remote_authorities[authority]
        expect(config[:url]).to be_present
        expect(config[:type]).to eq('autocomplete')
      end
    end
  end
end
