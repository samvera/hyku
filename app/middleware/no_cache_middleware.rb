# frozen_string_literal: true

# Taken from https://codeburst.io/service-workers-rails-middleware-841d0194144d
class NoCacheMiddleware
  # pass controllers when we register this middleware.
  def initialize(app, controllers)
    @app = app
    @controllers = controllers
  end

  def call(env)
    # Let the next middleware classes & app do their thing first...
    status, headers, response = @app.call(env)
    dont_cache = @controllers.any? { |controller_regex| env['REQUEST_PATH'] =~ controller_regex }

    # and modify the response if a controller was fetched.
    if dont_cache
      headers["Cache-Control"] = "no-cache, no-store, must-revalidate" # HTTP 1.1.
      headers["Pragma"] = "no-cache" # HTTP 1.0.
      headers["Expires"] = "0" # Proxies.
    end

    [status, headers, response]
  end
end
