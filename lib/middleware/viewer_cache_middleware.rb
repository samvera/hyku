# frozen_string_literal: true

# Viewer files copied into public/ keep their names across releases, so the year-long cache
# meant for fingerprinted assets would keep serving an old viewer after a deploy.
class ViewerCacheMiddleware
  VIEWER_PATHS = %r{\A/(uv|clover|ramp)/}

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    return [status, headers, body] unless env['PATH_INFO'].to_s.match?(VIEWER_PATHS)

    headers = headers.reject { |name, _| %w[cache-control expires].include?(name.downcase) }
    headers['Cache-Control'] = 'public, no-cache'
    [status, headers, body]
  end
end
