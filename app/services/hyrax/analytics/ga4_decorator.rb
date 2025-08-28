# frozen_string_literal: true

begin
  require "google/analytics/data/v1beta"
rescue LoadError
  # Google Analytics gem not available - analytics will be disabled
end

# OVERRIDE Hyrax v5.0.1
# This override modifies the Hyrax Google Analytics 4 reporting services to be tenant-aware.
# It also corrects several bugs in the original Hyrax GA4 implementation related to
# dimension handling and method calls.
module Hyrax
  module Analytics
    # OVERRIDE: The original hyrax code uses `include provider_parser` which includes
    # the GA4 methods as instance methods. We need them as class methods instead.
    # So we extend the module directly to get the class methods like `client`.
    extend Hyrax::Analytics::Ga4

    # OVERRIDE: Force the GA4 module to have the required class methods and Config class
    # In Docker environments, ActiveSupport::Concern class methods aren't being properly loaded
    # So we manually define the essential methods and classes here

    # Define the Config class if it doesn't exist
    unless defined?(Hyrax::Analytics::Ga4::Config)
      module Hyrax::Analytics::Ga4
        class Config
          def self.load_from_yaml
            filename = Rails.root.join('config', 'analytics.yml')
            return new({}) unless File.exist?(filename)

            yaml = YAML.safe_load(ERB.new(File.read(filename)).result)
            return new({}) unless yaml

            config = yaml.fetch('analytics')&.fetch('ga4', nil)
            return new({}) unless config

            new(config)
          end

          def initialize(config)
            @config = config
          end

          def analytics_id
            @config['analytics_id']
          end

          def property_id
            @config['property_id']
          end

          def account_json_string
            return @account_json_string if @account_json_string
            @account_json_string = begin
              if @config['account_json']
                base64?(@config['account_json']) ? Base64.decode64(@config['account_json']) : @config['account_json']
              elsif @config['account_json_path'] && File.exist?(@config['account_json_path'])
                File.read(@config['account_json_path'])
              else
                Rails.logger.error "No Google Analytics credentials found"
                "{}"
              end
                                   rescue => e
                                     Rails.logger.error "Failed to read account JSON: #{e.message}"
                                     "{}"
            end
          end

          def account_info
            @account_info ||= begin
              parsed = if account_json_string.is_a? Hash
                         account_json_string
                       else
                         JSON.parse(account_json_string)
                       end

              # Validate that we have the required keys for Google Auth
              required_keys = ['type', 'private_key', 'client_email']
              missing_keys = required_keys - parsed.keys
              if missing_keys.any?
                Rails.logger.error "Missing required keys in Google Analytics credentials: #{missing_keys}"
                return {}
              end

              # Fix common private key formatting issues
              parsed['private_key'] = parsed['private_key'].gsub('\\n', "\n") if parsed['private_key']&.include?('\\n')

              parsed
                              rescue => e
                                Rails.logger.error "Failed to parse account_info: #{e.message}"
                                {}
            end
          end

          def base64?(value)
            value.is_a?(String) && Base64.strict_encode64(Base64.decode64(value)) == value
          end
        end
      end
    end

    # Define the essential class methods if they don't exist
    unless Hyrax::Analytics::Ga4.respond_to?(:config)
      module Hyrax::Analytics::Ga4
        def self.config
          @config ||= Config.load_from_yaml
        end

        def self.client
          @client ||= begin
            # Check if we have valid credentials first
            account_info = config.account_info
            if account_info.empty?
              Rails.logger.warn "Google Analytics credentials not configured - analytics disabled"
              return nil
            end

            # Ensure the Google Analytics gem is loaded
            require "google/analytics/data/v1beta"
            ::Google::Analytics::Data::V1beta::AnalyticsData::Client.new do |conf|
              conf.credentials = account_info
            end
                      rescue LoadError => e
                        Rails.logger.error "Google Analytics gem not available: #{e.message}"
                        nil
                      rescue OpenSSL::PKey::RSAError => e
                        Rails.logger.error "Invalid Google Analytics credentials (RSA key error): #{e.message}"
                        Rails.logger.error "Please check your GOOGLE_ACCOUNT_JSON or GOOGLE_ACCOUNT_JSON_PATH configuration"
                        nil
                      rescue => e
                        Rails.logger.error "Failed to create analytics client: #{e.class} - #{e.message}"
                        nil
          end
        end

        def self.property
          "properties/#{config.property_id}"
        end

        def self.default_date_range
          "#{Hyrax.config.analytics_start_date},#{Time.zone.today + 1.day}"
        end

        def self.daily_events(action, date = default_date_range)
          date = date.split(",")
          EventsDaily.summary(date[0], date[1], action)
        end

        def self.daily_events_for_id(id, action, date = default_date_range)
          date = date.split(",")
          EventsDaily.by_id(date[0], date[1], id, action)
        end

        def self.top_events(action, date = default_date_range)
          date = date.split(",")
          Events.list(date[0], date[1], action)
        end

        def self.unique_visitors_for_id(_id, _date = default_date_range)
          # This method isn't implemented in GA4 yet, return empty result
          []
        end
      end
    end

    # Ensure the main Analytics module has the client method and proper delegations
    unless Hyrax::Analytics.respond_to?(:client)
      module Hyrax::Analytics
        def self.client
          Hyrax::Analytics::Ga4.client
        end

        def self.daily_events(*args)
          result = Hyrax::Analytics::Ga4.daily_events(*args)
          # Ensure the result responds to the methods the view expects
          if result && !result.respond_to?(:all)
            def result.all
              self
            end

            def result.empty?
              false
            end
          end
          result
        end

        def self.daily_events_for_id(*args)
          result = Hyrax::Analytics::Ga4.daily_events_for_id(*args)
          if result && !result.respond_to?(:all)
            def result.all
              self
            end

            def result.empty?
              false
            end
          end
          result
        end

        def self.top_events(*args)
          Hyrax::Analytics::Ga4.top_events(*args)
        end

        def self.unique_visitors_for_id(*_args)
          # Return a default result that responds to expected methods
          result = []
          def result.all
            self
          end

          def result.empty?
            true
          end
          result
        end

        def self.property
          Hyrax::Analytics::Ga4.property
        end

        def self.default_date_range
          Hyrax::Analytics::Ga4.default_date_range
        end
      end
    end

    module Ga4Decorator
      # A mapping of Hyrax event names to the custom dimension that should be used for grouping.
      # This is necessary because different reports need to be grouped by different IDs (e.g., work ID vs. collection ID).
      EVENT_DIMENSION_MAP = {
        'work-view' => 'contentId',
        'collection-page-view' => 'contentId',
        'file-set-download' => 'contentId',
        'work-in-collection-view' => 'collectionId',
        'work-in-collection-download' => 'collectionId',
        'file-set-in-work-download' => 'workId'
      }.freeze
      private_constant :EVENT_DIMENSION_MAP

      # Overrides the original daily_events to filter by tenant_id.
      def daily_events(action, date = default_date_range, tenant_id: nil)
        # Include required dimensions for results_array to work properly
        query = Hyrax::Analytics::Ga4::EventsDaily.new(
          start_date: date.split(',')[0],
          end_date: date.split(',')[1],
          dimensions: [{ name: 'date' }, { name: 'eventName' }]
        )
        query.add_filter(dimension: 'eventName', values: [action])
        add_tenant_filter(query, tenant_id) if tenant_id
        query.results_array
      end

      # Overrides the original daily_events_for_id to filter by tenant_id.
      def daily_events_for_id(id, action, date = default_date_range, tenant_id: nil)
        query = daily_events(action, date, tenant_id: tenant_id)
        dimension = EVENT_DIMENSION_MAP.fetch(action, 'contentId')
        query.add_filter(dimension: dimension, values: [id])
        query
      end

      # Overrides the original top_events to correctly handle dimensions and filter by tenant_id.
      def top_events(action, date = default_date_range, tenant_id: nil)
        # The original `list` class method is the correct way to fetch top events.
        # We are re-implementing it here to add the tenant_id filter.
        date_parts = date.is_a?(String) ? date.split(',') : date
        query = Hyrax::Analytics::Ga4::Events.new(start_date: date_parts[0], end_date: date_parts[1])

        query.add_filter(dimension: 'eventName', values: [action])
        add_tenant_filter(query, tenant_id) if tenant_id

        # This is the correct method to get the processed results.
        query.top_result_array
      end

      private

      # A helper method to add the tenant filter to a query object.
      def add_tenant_filter(query_object, tenant_id)
        query_object.add_filter(dimension: 'customEvent:tenant_id', values: [tenant_id])
      end
    end
  end
end

# The base class for Google Analytics 4 queries.
# This is being extended to include a tenant filtering method.
class Hyrax::Analytics::Ga4::Base
  def add_tenant_filter(tenant_id)
    add_filter(dimension: 'customEvent:tenant_id', values: [tenant_id])
  end

  # OVERRIDE Hyrax v5.0.1
  # This fixes a bug where the client was being called on the wrong module.
  # The client and its configuration live on the `Ga4` provider module.
  def results
    @results ||= begin
      client = Hyrax::Analytics::Ga4.client
      if client.nil?
        Rails.logger.warn "Analytics client not available - returning empty results"
        []
      else
        client.run_report(report).rows
      end
    end
  end
end

# Prepend the decorator to both the GA4 provider and the main Analytics module
# to ensure our tenant-aware methods are used everywhere.
Hyrax::Analytics::Ga4.singleton_class.prepend(Hyrax::Analytics::Ga4Decorator)
Hyrax::Analytics.singleton_class.prepend(Hyrax::Analytics::Ga4Decorator)
