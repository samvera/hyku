# frozen_string_literal: true

# Apply ArResourceDecorator to provide schema_version and contexts methods
# for Hyrax flexible metadata compatibility
Rails.application.config.to_prepare do
  if defined?(Hyrax::ArResource)
    Hyrax::ArResource.prepend(Hyrax::ArResourceDecorator)
  end
end