# frozen_string_literal: true

# Dev-only by default; staging can opt in via HYKU_MINI_PROFILER_ENABLED (see config/initializers/bullet.rb for why not Rails.env.staging?).
if Rails.env.development? || ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MINI_PROFILER_ENABLED', 'false'))
  require 'rack-mini-profiler'
  require 'stackprof'

  Rack::MiniProfiler.config.tap do |config|
    config.position = 'bottom-right'
    config.skip_paths = %w[/assets /packs /favicon.ico /up /health]
    config.storage_options = { path: Rails.root.join('tmp', 'miniprofiler') }

    # pre_authorize_cb runs before Warden, so gate via :allow_authorized + authorize_request below instead.
    config.authorization_mode = :allow_authorized unless Rails.env.development?
  end

  unless Rails.env.development?
    ActiveSupport.on_load(:action_controller) do
      before_action { Rack::MiniProfiler.authorize_request if current_user&.admin? || Flipflop.show_mini_profiler_to_all_users? }
    end
  end
end
