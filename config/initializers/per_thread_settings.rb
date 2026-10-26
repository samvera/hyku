# frozen_string_literal: true

# Per-tenant values that Account#switch! and AccountSettings#reload_library_config write into
# shared gem config. Each is kept per thread; see Hyku::PerThread.
Rails.application.config.to_prepare do
  Hyku::PerThread.attribute(Rails.application.routes.singleton_class, :default_url_options, copy: true)
  Hyku::PerThread.attribute(Hyrax::Engine.routes.singleton_class, :default_url_options, copy: true)
end
