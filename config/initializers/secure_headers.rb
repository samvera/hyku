SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: ActiveRecord::Type::Boolean.new.cast(Settings.ssl_configured) || SecureHeaders::OPT_OUT,
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      strict: true # mark all cookies as SameSite=Strict
    }
  }
  config.hsts = "max-age=#{20.years.to_i}; includeSubdomains; preload"
  config.x_frame_options = "SAMEORIGIN"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "origin-when-cross-origin"
  config.csp = SecureHeaders::OPT_OUT
end
