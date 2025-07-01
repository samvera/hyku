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
        'loc/subjects' => {
          url: "/authorities/search/loc/subjects",
          type: 'autocomplete'
        },
        'loc/names' => {
          url: "/authorities/search/loc/names", 
          type: 'autocomplete'
        },
        'loc/genre_forms' => {
          url: "/authorities/search/loc/genreForms",
          type: 'autocomplete'
        },
        'loc/countries' => {
          url: "/authorities/search/loc/countries",
          type: 'autocomplete'
        },
        'getty/aat' => {
          url: "/authorities/search/getty/aat",
          type: 'autocomplete'
        },
        'getty/tgn' => {
          url: "/authorities/search/getty/tgn",
          type: 'autocomplete'
        },
        'getty/ulan' => {
          url: "/authorities/search/getty/ulan",
          type: 'autocomplete'
        },
        'geonames' => {
          url: "/authorities/search/geonames",
          type: 'autocomplete'
        },
        'fast' => {
          url: "/authorities/search/assign_fast/topical",
          type: 'autocomplete'
        },
        'fast/all' => {
          url: "/authorities/search/assign_fast/all",
          type: 'autocomplete'
        },
        'fast/personal' => {
          url: "/authorities/search/assign_fast/personal",
          type: 'autocomplete'
        },
        'fast/corporate' => {
          url: "/authorities/search/assign_fast/corporate",
          type: 'autocomplete'
        },
        'fast/geographic' => {
          url: "/authorities/search/assign_fast/geographic",
          type: 'autocomplete'
        },
        'mesh' => {
          url: "/authorities/search/mesh",
          type: 'autocomplete'
        },
        'discogs' => {
          url: "/authorities/search/discogs/all",
          type: 'autocomplete'
        },
        'discogs/release' => {
          url: "/authorities/search/discogs/release",
          type: 'autocomplete'
        },
        'discogs/master' => {
          url: "/authorities/search/discogs/master",
          type: 'autocomplete'
        },
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

      # Ensure Discogs credentials are available for Discogs authorities
      if source.start_with?('discogs')
        ensure_discogs_credentials
      end

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

    private

    def ensure_discogs_credentials
      return unless Site.instance.respond_to?(:discogs_user_token)
      
      # Try Personal Access Token first (preferred)
      if Site.instance.discogs_user_token.present?
        Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = Site.instance.discogs_user_token
      elsif Site.instance.respond_to?(:discogs_key) && Site.instance.respond_to?(:discogs_secret) &&
            Site.instance.discogs_key.present? && Site.instance.discogs_secret.present?
        # Fall back to OAuth credentials
        Qa::Authorities::Discogs::GenericAuthority.discogs_key = Site.instance.discogs_key
        Qa::Authorities::Discogs::GenericAuthority.discogs_secret = Site.instance.discogs_secret
      end
    end
  end
end 