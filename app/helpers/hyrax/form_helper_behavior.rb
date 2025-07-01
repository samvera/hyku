# frozen_string_literal: true

module Hyrax
  module FormHelperBehavior
    def controlled_vocabulary_service_for(source_name)
      service_mapping = {
        'audience' => Hyrax::AudienceService,
        'discipline' => Hyrax::DisciplineService,
        'education_levels' => Hyrax::EducationLevelsService,
        'learning_resource_types' => Hyrax::LearningResourceTypesService,
        'oer_types' => Hyrax::OerTypesService
      }
      
      service_mapping[source_name]
    end

    def remote_authority_config_for(source_name)
      remote_authorities = {
        'loc_subjects' => {
          url: "/authorities/search/loc/subjects",
          type: 'autocomplete'
        },
        'loc_names' => {
          url: "/authorities/search/loc/names", 
          type: 'autocomplete'
        },
        'loc_genre_forms' => {
          url: "/authorities/search/loc/genreForms",
          type: 'autocomplete'
        },
        'geonames' => {
          url: "/authorities/search/geonames",
          type: 'autocomplete'
        },
        'fast_topics' => {
          url: "/authorities/search/oclc_fast/topic",
          type: 'autocomplete'
        }
      }
      
      remote_authorities[source_name]
    end

    def controlled_vocabulary_options_for(property_name, record_class)
      schema = Hyrax::FlexibleSchema.order("created_at asc").last
      return nil unless schema&.profile

      property_config = schema.profile.dig('properties', property_name.to_s)
      return nil unless property_config

      sources = property_config.dig('controlled_values', 'sources')
      return nil unless sources && !sources.include?('null')

      # Get the first non-null source and trim whitespace
      source = sources.find { |s| s != 'null' }&.strip
      return nil unless source

      # Check if it's a local service first
      service = controlled_vocabulary_service_for(source)
      if service
        begin
          return {
            type: 'select',
            options: service.select_all_options
          }
        rescue => e
          Rails.logger.warn "Failed to load controlled vocabulary for #{source}: #{e.message}"
          return nil
        end
      end

      # Check if it's a remote authority
      remote_config = remote_authority_config_for(source)
      if remote_config
        return {
          type: remote_config[:type],
          url: remote_config[:url]
        }
      end

      nil
    end
  end
end 