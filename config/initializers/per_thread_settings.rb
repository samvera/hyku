# frozen_string_literal: true

# Per-tenant values that Account#switch! and AccountSettings#reload_library_config write into
# shared gem config. Each is kept per thread; see Hyku::PerThread.
Rails.application.config.to_prepare do
  Hyku::PerThread.attribute(Rails.application.routes.singleton_class, :default_url_options, copy: true)
  Hyku::PerThread.attribute(Hyrax::Engine.routes.singleton_class, :default_url_options, copy: true)
end

Rails.application.config.to_prepare do
  {
    analytics: %i[analytics],
    analytics_reporting: %i[analytics_reporting analytics_reporting?],
    contact_email: %i[contact_email],
    display_media_download_link: %i[display_media_download_link?],
    solr_max_results: %i[solr_max_results],
    solr_rows_per_request: %i[solr_rows_per_request]
  }.each { |name, readers| Hyku::PerThread.attribute(Hyrax::Configuration, name, readers:) }
  # This reader memoizes with ||=, so a false tenant value still falls back to ENV
  Hyku::PerThread.attribute(Hyrax::Configuration, :analytics, readers: %i[analytics?], falsy_falls_back: true)
  Hyku::PerThread.attribute(Hyrax::Configuration, :uploader, copy: true)
end
