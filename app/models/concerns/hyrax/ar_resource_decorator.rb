# frozen_string_literal: true

module Hyrax
  module ArResourceDecorator
    extend ActiveSupport::Concern

    # Provides schema_version for resources when flexible metadata is used
    def schema_version
      # Handle test environment configuration caching issue:
      # Hyrax.config.flexible? caches result in @flexible instance variable
      # but tests may change ENV['HYRAX_FLEXIBLE'] without resetting the cache
      flexible_enabled = begin
        # Try using cached config first (normal case)
        Hyrax.config.flexible?
      rescue StandardError
        # Fall back to ENV if config isn't available
        ENV['HYRAX_FLEXIBLE'] == 'true'
      end

      # Also check ENV directly to handle test isolation issues
      flexible_enabled ||= ENV['HYRAX_FLEXIBLE'] == 'true'

      return '1.0' if flexible_enabled

      # Default behavior for non-flexible environments - check if super exists first
      begin
        if defined?(super)
          super
        else
          '1.0'
        end
      rescue NoMethodError
        # Provide a default if no parent implementation exists
        '1.0'
      end
    end

    # Provides contexts array for flexible metadata
    def contexts
      ['metadata']
    end
  end
end