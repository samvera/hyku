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

    def controlled_vocabulary_options_for(property_name, record_class)
      schema = Hyrax::FlexibleSchema.order("created_at asc").last
      return nil unless schema&.profile

      property_config = schema.profile.dig('properties', property_name.to_s)
      return nil unless property_config

      sources = property_config.dig('controlled_values', 'sources')
      return nil unless sources && !sources.include?('null')

      # Get the first non-null source
      source = sources.find { |s| s != 'null' }
      return nil unless source

      service = controlled_vocabulary_service_for(source)
      return nil unless service

      begin
        service.select_all_options
      rescue => e
        Rails.logger.warn "Failed to load controlled vocabulary for #{source}: #{e.message}"
        nil
      end
    end
  end
end 