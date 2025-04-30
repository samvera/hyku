# frozen_string_literal: true

# No more that 20 requests per minute per ip
limit = ENV.fetch('HYKU_ATTACK_RATE_LIMIT', 20).to_i
period = ENV.fetch('HYKU_ATTACK_RATE_PERIOD', 60).to_i
throttle_off = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ATTACK_RATE_THROTTLE_OFF', Rails.env.development? || Rails.env.test?))

unless throttle_off
  Rack::Attack.throttle('throttle catalog requests by ip', limit: limit, period: period) do |req|
    if req.path.starts_with?('/catalog') # rubocop:disable Style/IfUnlessModifier
      req.get_header('HTTP_X_ORIGINAL_FORWARDED_FOR') || req.ip
    end
  end

  FileUtils.mkdir_p(Rails.root.join('log', 'rack_attack'))
  throttle_logger = ActiveSupport::Logger.new(
    Rails.root.join('log', 'rack_attack', 'throttled_requests.log'),
    'daily'
  )
  throttle_logger.formatter = proc do |_severity, datetime, _progname, msg|
    "#{datetime.iso8601} #{msg}\n"
  end

  ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    origin_ip = req.get_header('HTTP_X_ORIGINAL_FORWARDED_FOR') || req.ip

    throttle_logger.info(
      "#{req.env['rack.attack.match_type']} " \
      "#{origin_ip} " \
      "#{req.env['rack.attack.match_data'][:count]}/#{req.env['rack.attack.match_data'][:limit]} " \
      "#{req.env['rack.attack.match_data'][:period]}s " \
      "#{req.request_method} " \
      "#{req.fullpath}"
    )
  end
end
