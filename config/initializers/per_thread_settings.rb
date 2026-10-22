# frozen_string_literal: true

# Per-tenant values that Account#switch! and AccountSettings#reload_library_config write into
# shared gem config. Each is kept per thread; see Hyku::PerThread.
Rails.application.config.to_prepare do
  Hyku::PerThread.attribute(Rails.application.routes.singleton_class, :default_url_options, copy: true)
  Hyku::PerThread.attribute(Hyrax::Engine.routes.singleton_class, :default_url_options, copy: true)
end

Rails.application.config.to_prepare do
  Hyku::PerThread.attribute(Rails.singleton_class, :cache)
  Hyku::PerThread.attribute(Rails.application.config.singleton_class, :cache_store)
  Hyku::PerThread.attribute(ActionController::Base.singleton_class, :perform_caching)
  Hyku::PerThread.attribute(ActionController::Base, :perform_caching, owner: ActionController::Base)
end
