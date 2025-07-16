# frozen_string_literal: true

module Hyrax
  module FormHelperBehavior
    def controlled_vocabulary_service_for(source_name)
      vocab = ControlledVocabulary.find_by(name: source_name, vocabulary_type: 'local')
      vocab&.service_class&.safe_constantize
    end

    def remote_authority_config_for(source_name)
      vocab = ControlledVocabulary.find_by(name: source_name, vocabulary_type: 'remote')
      vocab&.configuration&.with_indifferent_access
    end

    def controlled_vocabulary_options_for(property_name, _record_class)
      source = controlled_vocabulary_source_for(property_name)
      return unless source

      ensure_discogs_credentials if source.start_with?('discogs')

      local_vocabulary_options_for(source) || remote_vocabulary_options_for(source)
    end

    private

    def controlled_vocabulary_source_for(property_name)
      schema = Hyrax::FlexibleSchema.order("created_at asc").last
      return unless schema&.profile

      property_config = schema.profile.dig('properties', property_name.to_s)
      return unless property_config

      sources = property_config.dig('controlled_values', 'sources')
      return unless sources&.any? { |s| s != 'null' }

      # Get the first non-null source and trim whitespace
      sources.find { |s| s != 'null' }&.strip
    end

    def local_vocabulary_options_for(source)
      service_lookup = controlled_vocabulary_service_for(source)
      return unless service_lookup

      begin
        service = service_lookup.is_a?(Class) ? service_lookup.new : service_lookup
        {
          type: 'select',
          options: service.select_all_options,
          service: service
        }
      rescue StandardError => e
        Rails.logger.warn "Failed to load controlled vocabulary for #{source}: #{e.message}"
        nil
      end
    end

    def remote_vocabulary_options_for(source)
      remote_config = remote_authority_config_for(source)
      return unless remote_config

      {
        type: remote_config[:type],
        url: remote_config[:url]
      }
    end

    def ensure_discogs_credentials
      return unless Site.instance.respond_to?(:discogs_user_token)

      # Try Personal Access Token first (preferred)
      return if Site.instance.discogs_user_token.blank?

      Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = Site.instance.discogs_user_token
    end
  end
end
