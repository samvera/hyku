# frozen_string_literal: true

# OpenTelemetry tracing configuration
# Traces are exported to the local Alloy collector via OTLP,
# which then forwards them to the central Tempo instance.
#
# Required environment variables:
#   OTEL_EXPORTER_OTLP_ENDPOINT - e.g. http://alloy.monitoring.svc.cluster.local:4317
#   OTEL_SERVICE_NAME            - e.g. hyku-besties (set automatically below if not present)
#
# To disable tracing, omit the OTEL_EXPORTER_OTLP_ENDPOINT env var.
if ENV['OTEL_EXPORTER_OTLP_ENDPOINT'].present?
  require 'opentelemetry/sdk'
  require 'opentelemetry/exporter/otlp'
  require 'opentelemetry/instrumentation/all'

  # Determine version safely — this initializer runs before version.rb
  app_version = defined?(Hyku::VERSION) ? Hyku::VERSION : 'unknown'

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV.fetch('OTEL_SERVICE_NAME', "hyku-#{ENV.fetch('HYKU_ADMIN_HOST', 'unknown').split('.').first}")

    # Resource attributes for better trace identification
    c.resource = OpenTelemetry::SDK::Resources::Resource.create(
      'deployment.environment' => ENV.fetch('RAILS_ENV', 'production'),
      'service.namespace' => 'hyku',
      'service.version' => app_version
    )

    # Auto-instrument Rails, ActiveRecord, Faraday, Net::HTTP, Rack, Sidekiq, etc.
    c.use_all
  end

  Rails.logger.info "[OpenTelemetry] Tracing enabled → #{ENV['OTEL_EXPORTER_OTLP_ENDPOINT']}"
else
  Rails.logger.info "[OpenTelemetry] Tracing disabled (OTEL_EXPORTER_OTLP_ENDPOINT not set)"
end
