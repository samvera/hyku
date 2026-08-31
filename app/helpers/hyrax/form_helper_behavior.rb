# frozen_string_literal: true

module Hyrax
  module FormHelperBehavior
    def controlled_vocabulary_service_for(source_name)
      registered = Hyrax::ControlledVocabularies.services[source_name]&.safe_constantize
      return registered if registered

      # Dashboard-created vocabularies and unregistered yaml files are not in the
      # registry; without this fallback their fields render as free text.
      local_vocabulary_service_for(source_name)
    end

    def remote_authority_config_for(source_name)
      Hyrax::ControlledVocabularies.remote_authorities[source_name]
    end

    def controlled_vocabulary_options_for(property_name)
      source = controlled_vocabulary_source_for(property_name)
      return unless source

      # Only ensure Discogs credentials if we have a valid token
      ensure_discogs_credentials if source.start_with?('discogs') && discogs_configured?

      local_vocabulary_options_for(source) || remote_vocabulary_options_for(source)
    end

    # The authority name backing +property_name+, or nil when the property isn't
    # controlled. Public because callers that only need to label a stored value
    # want the source without building the whole option list.
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

    private

    # nil when neither a row nor a yaml file backs the name, so remote authorities
    # still get a chance.
    def local_vocabulary_service_for(source_name)
      name = source_name.to_s
      return if name.blank?
      return unless Qa::LocalAuthority.exists?(name: name) || file_based_authority?(name)

      Hyrax::TolerantSelectService.new(name)
    rescue StandardError => e
      Rails.logger.warn "Failed to build a vocabulary service for #{source_name}: #{e.message}"
      nil
    end

    # Rescued because qa raises ConfigDirectoryNotFound when a deployment has no
    # config/authorities — no yaml vocabularies to match, not a broken form.
    def file_based_authority?(name)
      Qa::Authorities::Local.names.include?(name)
    rescue StandardError => e
      Rails.logger.debug { "Unable to list file-based local authorities: #{e.message}" }
      false
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
