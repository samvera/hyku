# frozen_string_literal: true

module Hyrax
  module FormHelperBehavior
    def controlled_vocabulary_service_for(source_name)
      Hyrax::ControlledVocabularies.services[source_name]&.safe_constantize
    end

    def remote_authority_config_for(source_name)
      Hyrax::ControlledVocabularies.remote_authorities[source_name]
    end

    def controlled_vocabulary_options_for(property_name, record_class)
      # TODO: Metadata property overrides for specific classes will soon be available in Hyrax
      # Temporary workaround to support OER override
      source = if record_class.present? && property_name == :resource_type && record_class.name.start_with?('Oer')
                 'oer_types'
               else
                 controlled_vocabulary_source_for(property_name)
               end

      return unless source

      # Only ensure Discogs credentials if we have a valid token
      ensure_discogs_credentials if source.start_with?('discogs') && discogs_configured?

      local_vocabulary_options_for(source) || remote_vocabulary_options_for(source)
    end

    private

    def controlled_vocabulary_source_for(property_name)
      if Hyrax.config.flexible?
        schema = Hyrax::FlexibleSchema.order("created_at asc").last
        return unless schema&.profile

        property_config = schema.profile.dig('properties', property_name.to_s)
        return unless property_config

        sources = property_config.dig('controlled_values', 'sources')
        return unless sources&.any? { |s| s != 'null' }

        # Get the first non-null source and trim whitespace
        sources.find { |s| s != 'null' }&.strip
      else
        controlled_vocabulary_mapping_for(property_name)
      end
    end

    def controlled_vocabulary_mapping_for(property_name)
      # Maps property names in when flexible=false to their corresponding controlled vocabulary service keys
      # Hyku: config/initializers/hyrax_controlled_vocabularies.rb
      Hyrax::ControlledVocabularies.controlled_vocab_mappings[property_name.to_s]
    end

    def local_vocabulary_options_for(source)
      service_lookup = controlled_vocabulary_service_for(source)
      return unless service_lookup

      begin
        service = service_lookup.is_a?(Class) ? service_lookup.new : service_lookup

        # Handle different service patterns:
        # 1. Most services use select_all_options
        # 2. Some, like ResourceTypesService, uses select_options
        options = if service.respond_to?(:select_active_options)
                    service.select_active_options
                  elsif service.respond_to?(:select_all_options)
                    service.select_all_options
                  elsif service.respond_to?(:select_options)
                    service.select_options
                  else
                    Rails.logger.warn "Service #{service.class} does not have select_all_options or select_options method"
                    []
                  end

        {
          type: 'select',
          options: options,
          service: service
        }
      rescue StandardError => e
        Rails.logger.warn "Failed to load controlled vocabulary for #{source}: #{e.message}"
        nil
      end
    end

    def remote_vocabulary_options_for(source)
      # Skip Discogs authorities if not properly configured
      return nil if source.start_with?('discogs') && !discogs_configured?

      remote_config = remote_authority_config_for(source)
      return unless remote_config

      {
        type: remote_config[:type],
        url: remote_config[:url]
      }
    end

    def discogs_configured?
      return false unless current_account.respond_to?(:discogs_user_token)
      current_account.discogs_user_token.present?
    end

    def ensure_discogs_credentials
      return unless current_account.respond_to?(:discogs_user_token)

      unless discogs_config_files_exist?
        Rails.logger.warn('Discogs user token is present, but config/discogs-genres.yml and/or config/discogs-formats.yml are missing. Discogs integration is disabled.')
        return
      end

      # Clear token if current tenant doesn't have one configured
      if current_account.discogs_user_token.blank?
        Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = nil
        return
      end

      # Set token for current tenant
      Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = current_account.discogs_user_token
    end

    def discogs_config_files_exist?
      File.exist?(Rails.root.join('config', 'discogs-genres.yml')) &&
        File.exist?(Rails.root.join('config', 'discogs-formats.yml'))
    end
  end
end
