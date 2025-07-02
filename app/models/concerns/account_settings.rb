# frozen_string_literal: true

# All settings have a presedence order as follows
# Per Tenant Setting > ENV['HYKU_SETTING_NAME'] > ENV['HYRAX_SETTING_NAME'] > default

# rubocop:disable Metrics/ModuleLength
module AccountSettings
  extend ActiveSupport::Concern
  # rubocop:disable Metrics/BlockLength
  included do
    cattr_accessor :array_settings, :boolean_settings, :hash_settings, :json_editor_settings, :string_settings, :private_settings do
      []
    end
    cattr_accessor :all_settings do
      {}
    end

    ##
    # Consider the configured superadmin_settings only available for those with
    # the superadmin role.
    class_attribute :superadmin_settings, default: []

    setting :allow_downloads, type: 'boolean', default: true
    setting :allow_signup, type: 'boolean', default: true
    setting :analytics, type: 'boolean', default: false
    setting :analytics_reporting, type: 'boolean', default: false
    setting :batch_email_notifications, type: 'boolean', default: false
    setting :bulkrax_field_mappings, type: 'json_editor', default: Hyku.default_bulkrax_field_mappings.to_json
    setting :bulkrax_validations, type: 'boolean', disabled: true
    setting :cache_api, type: 'boolean', default: false
    setting :contact_email, type: 'string', default: 'change-me-in-settings@example.com'
    setting :contact_email_to, type: 'string', default: 'change-me-in-settings@example.com'
    setting :depositor_email_notifications, type: 'boolean', default: false
    setting :doi_reader, type: 'boolean', default: false
    setting :doi_writer, type: 'boolean', default: false
    setting :file_acl, type: 'boolean', default: true, private: true
    setting :email_domain, type: 'string', default: 'example.com'
    setting :email_format, type: 'array'
    setting :email_subject_prefix, type: 'string'
    setting :enable_oai_metadata, type: 'string', disabled: true
    setting :file_size_limit, type: 'string', default: 5.gigabytes.to_s
    setting :google_analytics_id, type: 'string', default: ENV.fetch('GOOGLE_ANALYTICS_ID', '')
    setting :google_analytics_property_id, type: 'string', default: ENV.fetch('GOOGLE_ANALYTICS_PROPERTY_ID', '')
    setting :google_scholarly_work_types, type: 'array', disabled: true
    setting :geonames_username, type: 'string', default: ''
    setting :discogs_user_token, type: 'string', private: true
    setting :gtm_id, type: 'string'
    setting :hidden_index_fields, type: 'string', default: 'title'
    setting :locale_name, type: 'string', disabled: true
    setting :monthly_email_list, type: 'array', disabled: true
    setting :oai_admin_email, type: 'string', default: 'changeme@example.com'
    setting :oai_prefix, type: 'string', default: 'oai:hyku'
    setting :oai_sample_identifier, type: 'string', default: '806bbc5e-8ebe-468c-a188-b7c14fbe34df'
    setting :s3_bucket, type: 'string', private: true
    setting :shared_login, type: 'boolean', disabled: true
    setting :smtp_settings, type: 'hash', private: true, default: {}
    setting :solr_collection_options, type: 'hash', default: solr_collection_options
    setting :ssl_configured, type: 'boolean', default: true, private: true
    setting :weekly_email_list, type: 'array', disabled: true
    setting :yearly_email_list, type: 'array', disabled: true

    store :settings, coder: JSON, accessors: all_settings.keys

    validates :gtm_id, format: { with: /GTM-[A-Z0-9]{4,7}/, message: "Invalid GTM ID" }, allow_blank: true
    validates :contact_email, :oai_admin_email,
              format: { with: URI::MailTo::EMAIL_REGEXP },
              allow_blank: true
    validate :validate_email_format, :validate_contact_emails, :validate_json
    validates :google_analytics_id,
              format: { with: /((UA|YT|MO)-\d+-\d+|G-[A-Z0-9]{10})/i },
              allow_blank: true

    after_initialize :initialize_settings
  end
  # rubocop:enable Metrics/BlockLength

  # rubocop:disable Metrics/BlockLength
  class_methods do
    def setting(name, args)
      known_type = ['array', 'boolean', 'hash', 'string', 'json_editor'].include?(args[:type])
      raise "Setting type #{args[:type]} is not supported. Can not laod." unless known_type

      send("#{args[:type]}_settings") << name
      all_settings[name] = args
      private_settings << name if args[:private]

      # watch out because false is a valid value to return here
      define_method(name) do
        value = super()
        value = value.nil? ? ENV.fetch("HYKU_#{name.upcase}", nil) : value
        value = value.nil? ? ENV.fetch("HYRAX_#{name.upcase}", nil) : value
        value = value.nil? ? ENV.fetch(name.upcase.to_s, nil) : value
        value = value.nil? ? args[:default] : value
        set_type(value, (args[:type]).to_s)
      end
    end

    # rubocop:disable Metrics/MethodLength
    def solr_collection_options
      {
        async: nil,
        auto_add_replicas: nil,
        collection: {
          config_name: ENV.fetch('SOLR_CONFIGSET_NAME', 'hyku')
        },
        create_node_set: nil,
        max_shards_per_node: nil,
        num_shards: 1,
        replication_factor: nil,
        router: {
          name: nil,
          field: nil
        },
        rule: nil,
        shards: nil,
        snitch: nil
      }
    end
    # rubocop:disable Metrics/MethodLength
  end
  # rubocop:enable Metrics/BlockLength

  def public_settings(is_superadmin: false)
    all_settings.reject do |key, value|
      value[:disabled] ||
        self.class.private_settings.include?(key.to_s) ||
        (!is_superadmin && superadmin_settings.include?(key.to_sym))
    end
  end

  def live_settings
    all_settings.reject { |_k, v| v[:disabled] }
  end

  private

  def set_type(value, to_type)
    case to_type
    when 'array'
      value.is_a?(String) ? value.split(',') : Array.wrap(value)
    when 'boolean'
      ActiveModel::Type::Boolean.new.cast(value)
    when 'hash'
      value.is_a?(String) ? JSON.parse(value) : value
    when 'string'
      value.to_s
    when 'json_editor'
      begin
        JSON.pretty_generate(JSON.parse(value))
      rescue JSON::ParserError
        value
      end
    end
  end

  def validate_email_format
    return if settings['email_format'].blank?
    settings['email_format'].each do |email|
      errors.add(:email_format) unless email.match?(/@\S*\.\S*/)
    end
  end

  def validate_contact_emails
    ['weekly_email_list', 'monthly_email_list', 'yearly_email_list'].each do |key|
      next if settings[key].blank?
      settings[key].each do |email|
        errors.add(:"#{key}") unless email.match?(URI::MailTo::EMAIL_REGEXP)
      end
    end
  end

  def validate_json
    json_editor_settings.each do |key|
      next if settings[key].blank?

      begin
        JSON.parse(settings[key])
      rescue JSON::ParserError => e
        errors.add(:"#{key}", e.message)
      end
    end
  end

  def initialize_settings
    return true unless self.class.column_names.include?('settings')
    set_smtp_settings
    reload_library_config
  end

  def set_smtp_settings
    current_smtp_settings = settings&.[]("smtp_settings").presence || {}
    self.smtp_settings = current_smtp_settings.with_indifferent_access.reverse_merge!(
      PerTenantSmtpInterceptor.available_smtp_fields.each_with_object("").to_h
    )
  end

  def reload_library_config
    configure_hyrax
    reload_hyrax_analytics
    configure_devise
    configure_carrierwave
    configure_ssl
  end

  def configure_hyrax
    Hyrax.config do |config|
      # A short-circuit of showing download links
      config.display_media_download_link = allow_downloads.nil? || ActiveModel::Type::Boolean.new.cast(allow_downloads)
      config.contact_email = contact_email
      config.geonames_username = geonames_username
      config.uploader[:maxFileSize] = file_size_limit.to_i
      # Configure Discogs API credentials for Questioning Authority
      if File.exist?(Rails.root.join('config', 'discogs-genres.yml')) &&
         File.exist?(Rails.root.join('config', 'discogs-formats.yml')) &&
         discogs_user_token.present?

        Qa::Authorities::Discogs::GenericAuthority.discogs_user_token = discogs_user_token
      end
      configure_hyrax_analytics_settings(config)
    end
  end

  def configure_hyrax_analytics_settings(config)
    if ActiveModel::Type::Boolean.new.cast(analytics_reporting) && analytics_credentials_present?
      config.analytics = true
      config.analytics_reporting = true
    else
      config.analytics = false
      config.analytics_reporting = false
    end
  end

  def configure_devise
    Devise.mailer_sender = contact_email
  end

  def configure_carrierwave
    CarrierWave.configure do |config|
      if s3_bucket.present?
        configure_s3_storage(config)
      elsif !file_acl
        configure_no_permissions(config)
      else
        configure_file_storage(config)
      end
    end
  end

  def configure_s3_storage(config)
    config.storage = :aws
    config.aws_bucket = s3_bucket
    config.aws_acl = 'bucket-owner-full-control'
  end

  def configure_no_permissions(config)
    config.permissions = nil
    config.directory_permissions = nil
  end

  def configure_file_storage(config)
    config.storage = :file
    config.permissions = 420
    config.directory_permissions = 493
  end

  def configure_ssl
    return unless ssl_configured
    ActionMailer::Base.default_url_options ||= {}
    ActionMailer::Base.default_url_options[:protocol] = 'https'
  end

  def analytics_credentials_present?
    google_analytics_id.present? &&
      google_analytics_property_id.present? &&
      (ENV.fetch('GOOGLE_ACCOUNT_JSON', '').present? || ENV.fetch('GOOGLE_ACCOUNT_JSON_PATH', '').present?)
  end

  def reload_hyrax_analytics
    # Configure analytics if all required settings are present
    if google_analytics_id.present? &&
       google_analytics_property_id.present? &&
       (ENV.fetch('GOOGLE_ACCOUNT_JSON', '').present? || ENV.fetch('GOOGLE_ACCOUNT_JSON_PATH', '').present?)

      Hyrax::Analytics.config.analytics_id = google_analytics_id
      Hyrax::Analytics.config.property_id = google_analytics_property_id

    else
      # Disable analytics if any required settings are missing
      Hyrax.config.analytics = false
      Hyrax.config.analytics_reporting = false
    end
  rescue StandardError => e
    # Log the error but don't crash the application
    Rails.logger.error "Failed to configure analytics: #{e.message}"
    Hyrax.config.analytics = false
    Hyrax.config.analytics_reporting = false
  end
end
# rubocop:enable Metrics/ModuleLength
