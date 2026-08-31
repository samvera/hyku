# frozen_string_literal: true

# request_store's own Rack middleware clears RequestStore at the end of every
# HTTP request (see request_store/railtie.rb), but that doesn't cover
# background jobs: GoodJob and Sidekiq both reuse threads across job
# executions, so anything stashed in RequestStore during one job (e.g.
# Site.instance, Draper's current view context, Lograge's captured redirect
# location) could otherwise leak into the next job run on that thread. This
# mirrors the ensure-based clear in request_store-sidekiq's server
# middleware (https://github.com/madebylotus/request_store-sidekiq), but via
# ActiveJob's own around_perform callback so it applies regardless of queue
# adapter.
module ActiveJobRequestStoreReset
  extend ActiveSupport::Concern

  included do
    around_perform do |_job, block|
      block.call
    ensure
      RequestStore.clear!
    end
  end
end
