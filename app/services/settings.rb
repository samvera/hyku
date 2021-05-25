# frozen_string_literal: true

class Settings
  def self.switch!(name: nil, settings: {})
    settings_files = Config.setting_files(Rails.root.join('config'), Rails.env)
    settings_files += [tenant_settings_filename(name)] if name
    config = Config.load_files(settings_files)
    config.add_source!(Config::Sources::EnvSource.new(ENV, prefix: tenant_settings_prefix(name))) if name
    config.add_source!(settings)
    config.reload!
    Thread.current[:settings] = config
    reload_hyrax_config!
    config
  end

  # Disable rubocop because Settings will return nil for an undefined method
  # instead of raising an exception and we want to mirror that behavior
  # rubocop:disable Style/MethodMissing
  def self.method_missing(method_id)
    switch! if Thread.current[:settings].blank?
    Thread.current[:settings].send(method_id)
  end
  # rubocop:enable Style/MethodMissing

  def self.respond_to_missing?(method_name, include_all)
    super
  end

  def self.tenant_settings_filename(name)
    Rails.root.join('config', 'settings', "#{Rails.env}-#{name.upcase}.yml")
  end

  def self.tenant_settings_prefix(name)
    [Config.env_prefix, name.upcase].compact.join(Config.env_separator)
  end

  # Reload all hyrax configuration that reads from Settings
  # TODO: Figure out a better way to do this
  def self.reload_hyrax_config!
    Hyrax.config do |config|
      # DO NOT reload the redis_namespace because this is already handled by redis_endpoint.switch!
      config.contact_email = Settings.contact_email
      config.analytics = Settings.google_analytics_id.present?
      config.google_analytics_id = Settings.google_analytics_id
      config.fits_path = Settings.fits_path
      config.geonames_username = Settings.geonames_username
    end
  end
end
