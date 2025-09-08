# frozen_string_literal: true

class DiscogsCredsConfig
  def self.setup
    new.setup
  end

  def setup
    return unless discogs_authority_defined? && discogs_config_files_exist?

    set_token_from_site
    set_token_from_env
  end

  private

  def discogs_authority_defined?
    defined?(Qa::Authorities::Discogs::GenericAuthority)
  end

  def discogs_config_files_exist?
    File.exist?(Rails.root.join('config', 'discogs-genres.yml')) &&
      File.exist?(Rails.root.join('config', 'discogs-formats.yml'))
  end

  def set_token_from_site
    return unless site_defined? && db_table_exists?

    site = Site.instance
    return unless site.respond_to?(:discogs_user_token) && site.discogs_user_token.present?

    Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = site.discogs_user_token
  rescue StandardError => e
    Rails.logger.debug "Could not load account settings for Discogs: #{e.message}"
  end

  def site_defined?
    defined?(Site) && Site.respond_to?(:instance)
  end

  def db_table_exists?
    ApplicationRecord.connection.table_exists?(Site.table_name)
  rescue ActiveRecord::NoDatabaseError
    false
  end

  def set_token_from_env
    return if Qa::Authorities::Discogs::GenericAuthority.discogs_user_token.present?

    env_token = ENV.fetch('HYKU_DISCOGS_USER_TOKEN', nil) ||
                ENV.fetch('HYRAX_DISCOGS_USER_TOKEN', nil) ||
                ENV.fetch('DISCOGS_USER_TOKEN', nil)

    Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = env_token if env_token.present?
  end
end
