# frozen_string_literal: true

# Rack::Attack.cache memoizes Rails.cache on first access, but Account#setup_tenant_cache
# flips Rails.cache between Redis and a FileStore per tenant per request. Pin it to Redis
# so it can't get stuck on the FileStore variant under concurrent requests (Errno::ESTALE).
cache_store_url = ENV['RAILS_CACHE_STORE_URL']

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: cache_store_url) if cache_store_url.to_s.start_with?('redis')
