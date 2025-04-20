# frozen_string_literal: true
# No more that 20 requersts per minitue per ip
limit = ENV.fetch('HYKU_ATTACK_RATE_LIMIT', 20)
period = ENV.fetch('HYKU_ATTACK_RATE_PERIOD', 60)
throttle_off = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ATTACK_RATE_THROTTLE_OFF', Rails.env.development? || Rails.env.test?))
Rack::Attack.throttle("requests by ip", limit: limit, period: period, &:ip) unless throttle_off
