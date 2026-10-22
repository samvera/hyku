# frozen_string_literal: true

# Per-tenant values that Account#switch! and AccountSettings#reload_library_config write into
# shared gem config. Each is kept per thread; see Hyku::PerThread.
Rails.application.config.to_prepare do
  Hyku::PerThread.attribute(Rails.application.routes.singleton_class, :default_url_options, copy: true)
  Hyku::PerThread.attribute(Hyrax::Engine.routes.singleton_class, :default_url_options, copy: true)
end

Rails.application.config.to_prepare do
  # Hyrax's reader memoizes with ||=, so a blank tenant value still falls back to ENV
  Hyku::PerThread.attribute(Hyrax::Configuration, :redis_namespace, falsy_falls_back: true)
  if defined?(Valkyrie::Indexing::RedisQueue::IndexingAdapter)
    %i[index_queue_name delete_queue_name].each do |name|
      Hyku::PerThread.attribute(Valkyrie::Indexing::RedisQueue::IndexingAdapter, name)
    end
  end
end
