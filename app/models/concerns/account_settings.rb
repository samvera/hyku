# frozen_string_literal: true

module AccountSettings
  extend ActiveSupport::Concern
  # rubocop:disable Metrics/BlockLength
  included do
    cattr_accessor :array_settings, :boolean_settings, :hash_settings, :string_settings, :private_settings do
      []
    end
    cattr_accessor :all_settings do
      {}
    end

    setting :allow_signup, type: 'boolean', default: true
    setting :bulkrax_validations, type: 'boolean'
    setting :cache_api, type: 'boolean', default: false
    setting :contact_email, type: 'string'
    setting :doi_reader, type: 'boolean', default: false
    setting :doi_writer, type: 'boolean', default: false
    setting :email_format, type: 'array'
    setting :enable_oai_metadata, type: 'string'
    setting :file_size_limit, type: 'string'
    setting :google_analytics_id, type: 'string'
    setting :google_scholarly_work_types, type: 'string'
    setting :gtm_id, type: 'string'
    setting :locale_name, type: 'string'
    setting :monthly_email_list, type: 'array'
    setting :oai_admin_email, type: 'string'
    setting :oai_prefix, type: 'string'
    setting :oai_sample_identifier, type: 'string'
    setting :shared_login, type: 'boolean'
    setting :smtp_settings, type: 'hash', private: true
    setting :weekly_email_list, type: 'array'
    setting :yearly_email_list, type: 'array'

    store :settings, coder: JSON, accessors: all_settings.keys

    validates :gtm_id, format: { with: /GTM-[A-Z0-9]{4,7}/, message: "Invalid GTM ID" }, allow_blank: true
    validates :contact_email, :oai_admin_email,
              format: { with: URI::MailTo::EMAIL_REGEXP },
              allow_blank: true
    validate :validate_email_format, :validate_contact_emails
    validates :google_analytics_id,
              format: { with: /((UA|YT|MO)-\d+-\d+|G-[A-Z0-9]{10})/i },
              allow_blank: true

    after_initialize :initialize_settings
  end
  # rubocop:enable Metrics/BlockLength

  class_methods do
    def setting(name, args)
      known_type = ['array', 'boolean', 'hash', 'string'].include?(args[:type])
      raise "Setting type #{args[:type]} is not supported. Can not laod." unless known_type

      send("#{args[:type]}_settings") << name
      all_settings[name] = args
      private_settings << name if args[:private]
    end
  end

  def public_settings
    settings.reject { |k, _v| Account.private_settings.include?(k.to_s) }
  end

  private

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

    def initialize_settings
      set_smtp_settings
    end

    def set_smtp_settings
      current_smtp_settings = settings["smtp_settings"].presence || {}
      self.smtp_settings = current_smtp_settings.with_indifferent_access.reverse_merge!(
        PerTenantSmtpInterceptor.available_smtp_fields.each_with_object("").to_h
      )
    end
end
