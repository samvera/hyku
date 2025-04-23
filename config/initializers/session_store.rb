# frozen_string_literal: true
# Be sure to restart your server when you modify this file.
redis_url = ENV.fetch('REDIS_URL', false)
if redis_url
  session_url = "#{redis_url}/session"
  secure = Rails.env.production? || Rails.env.staging?
  key = Rails.env.production? ? "_hyku_session" : "_hyku_session_#{Rails.env}"

  Rails.application.config.session_store :redis_store,
    url: session_url,
    expire_after: 180.days,
    key: key,
    threadsafe: true,
    secure: secure,
    same_site: :lax,
    httponly: true
else
  Rails.application.config.session_store :cookie_store, key: '_hyku_session'
end
