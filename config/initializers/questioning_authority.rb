# Configure Questioning Authority with dynamic credentials

Rails.application.config.to_prepare do
  # Ensure Discogs credentials are available from various sources
  if defined?(Qa::Authorities::Discogs::GenericAuthority)
    # Try to get credentials from current account settings if available
    if defined?(Site) && Site.respond_to?(:instance)
      begin
        site = Site.instance
        if site.respond_to?(:discogs_key) && site.respond_to?(:discogs_secret)
          discogs_key = site.discogs_key
          discogs_secret = site.discogs_secret
          
          if discogs_key.present? && discogs_secret.present?
            Qa::Authorities::Discogs::GenericAuthority.discogs_key = discogs_key
            Qa::Authorities::Discogs::GenericAuthority.discogs_secret = discogs_secret
          end
        end
      rescue => e
        Rails.logger.debug "Could not load account settings for Discogs: #{e.message}"
      end
    end
    
    # Fallback to environment variables if account settings aren't available
    if Qa::Authorities::Discogs::GenericAuthority.discogs_key.blank?
      env_key = ENV.fetch('HYKU_DISCOGS_KEY', ENV.fetch('DISCOGS_KEY', nil))
      env_secret = ENV.fetch('HYKU_DISCOGS_SECRET', ENV.fetch('DISCOGS_SECRET', nil))
      
      if env_key.present? && env_secret.present?
        Qa::Authorities::Discogs::GenericAuthority.discogs_key = env_key
        Qa::Authorities::Discogs::GenericAuthority.discogs_secret = env_secret
      end
    end
  end
end 