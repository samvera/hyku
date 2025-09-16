# frozen_string_literal: true
# Configure Questioning Authority with dynamic credentials

Rails.application.config.to_prepare do
  DiscogsCredsConfig.setup
end
