# frozen_string_literal: true

# Ensure clover_viewer feature exists in the database for all tenants
Rails.application.config.after_initialize do
  # This runs after the application is initialized
  begin
    # Only create if it doesn't exist to avoid duplicates
    unless Flipflop::Feature.exists?(key: 'clover_viewer')
      Flipflop::Feature.create!(key: 'clover_viewer', enabled: false)
      Rails.logger.info "Created clover_viewer feature in Flipflop"
    end
  rescue => e
    # Log but don't fail if there's an issue
    Rails.logger.warn "Could not create clover_viewer feature: #{e.message}"
  end
end