# Configure Questioning Authority with dynamic credentials

Rails.application.config.to_prepare do
  # Ensure Discogs credentials are available from various sources
  if defined?(Qa::Authorities::Discogs::GenericAuthority)
    # Enable discogs integration only when the config files are present
    if File.exist?(Rails.root.join('config', 'discogs-genres.yml')) &&
       File.exist?(Rails.root.join('config', 'discogs-formats.yml'))

      # Try to get credentials from current account settings if available
      if defined?(Site) && Site.respond_to?(:instance)
        begin
          site = Site.instance
          if site.respond_to?(:discogs_user_token) && site.discogs_user_token.present?
            Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = site.discogs_user_token
          end
        rescue => e
          Rails.logger.debug "Could not load account settings for Discogs: #{e.message}"
        end
      end

      # Fallback to environment variables if account settings aren't available
      if Qa::Authorities::Discogs::GenericAuthority.discogs_user_token.blank?
        env_token = ENV.fetch('HYKU_DISCOGS_USER_TOKEN', nil) ||
                    ENV.fetch('HYRAX_DISCOGS_USER_TOKEN', nil) ||
                    ENV.fetch('DISCOGS_USER_TOKEN', nil)

        if env_token.present?
          Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = env_token
        end
      end
    end
  end
end 