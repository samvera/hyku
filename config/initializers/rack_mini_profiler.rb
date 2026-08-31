# frozen_string_literal: true

# Dev-only by default; staging can opt in via HYKU_MINI_PROFILER_ENABLED (see config/initializers/bullet.rb for why not Rails.env.staging?).
if Rails.env.development? || ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MINI_PROFILER_ENABLED', 'false'))
  require 'rack-mini-profiler'
  require 'stackprof'

  Rack::MiniProfiler.config.tap do |config|
    config.position = 'bottom-right'
    config.skip_paths = %w[/assets /packs /favicon.ico /up /health]
    config.storage_options = { path: Rails.root.join('tmp', 'miniprofiler') }
    config.enable_advanced_debugging_tools = true
  end
end
