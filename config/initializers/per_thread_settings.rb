# frozen_string_literal: true

# Per-tenant values that Account#switch! and AccountSettings#reload_library_config write into
# shared gem config. Each is kept per thread; see Hyku::PerThread.
Rails.application.config.to_prepare do
  Hyku::PerThread.attribute(Rails.application.routes.singleton_class, :default_url_options, copy: true)
  Hyku::PerThread.attribute(Hyrax::Engine.routes.singleton_class, :default_url_options, copy: true)
  {
    analytics: %i[analytics],
    analytics_reporting: %i[analytics_reporting],
    contact_email: %i[contact_email],
    display_media_download_link: %i[display_media_download_link?],
    solr_max_results: %i[solr_max_results],
    solr_rows_per_request: %i[solr_rows_per_request]
  }.each { |name, readers| Hyku::PerThread.attribute(Hyrax::Configuration, name, readers:) }
  # These readers memoize with ||=, so a false tenant value still falls back to ENV
  {
    analytics: %i[analytics?],
    analytics_reporting: %i[analytics_reporting?]
  }.each { |name, readers| Hyku::PerThread.attribute(Hyrax::Configuration, name, readers:, falsy_falls_back: true) }
  Hyku::PerThread.attribute(Hyrax::Configuration, :uploader, copy: true)
  Hyku::PerThread.attribute(Rails.singleton_class, :cache)
  Hyku::PerThread.attribute(Rails.application.config.singleton_class, :cache_store)
  Hyku::PerThread.attribute(ActionController::Base.singleton_class, :perform_caching)
  Hyku::PerThread.attribute(ActionController::Base, :perform_caching, owner: ActionController::Base)
  %i[_storage aws_bucket aws_acl permissions directory_permissions].each do |name|
    next unless CarrierWave::Uploader::Base.respond_to?(name)
    Hyku::PerThread.attribute(CarrierWave::Uploader::Base.singleton_class, name)
  end
  Hyku::PerThread.attribute(Devise.singleton_class, :mailer_sender)
  # Hyrax's reader memoizes with ||=, so a blank tenant value still falls back to ENV
  Hyku::PerThread.attribute(Hyrax::Configuration, :redis_namespace, falsy_falls_back: true)
  if defined?(Valkyrie::Indexing::RedisQueue::IndexingAdapter)
    %i[index_queue_name delete_queue_name].each do |name|
      Hyku::PerThread.attribute(Valkyrie::Indexing::RedisQueue::IndexingAdapter, name)
    end
  end
end