# frozen_string_literal: true

require Rails.root.join('lib', 'middleware', 'viewer_cache_middleware')

RSpec.describe ViewerCacheMiddleware do
  subject(:middleware) { described_class.new(app) }

  let(:app) do
    lambda do |_env|
      [200, { 'Cache-Control' => 'public, s-maxage=31536000, max-age=15552000', 'Expires' => 'a year away' }, ['ok']]
    end
  end

  def headers_for(path)
    middleware.call(Rack::MockRequest.env_for(path))[1].transform_keys(&:downcase)
  end

  %w[/clover/clover.html /clover/clover.js /uv/uv.html /uv/uv-config.json /ramp/ramp.html].each do |path|
    it "has browsers and CDNs revalidate #{path} instead of keeping it for a year" do
      headers = headers_for(path)

      expect(headers['cache-control']).to eq 'public, no-cache'
      expect(headers['expires']).to be_nil
    end
  end

  it "leaves the long cache on fingerprinted assets" do
    expect(headers_for('/assets/application-abc123.css')['cache-control']).to eq 'public, s-maxage=31536000, max-age=15552000'
  end

  it "leaves paths that only start with a viewer's name alone" do
    expect(headers_for('/clover-notes.html')['cache-control']).to eq 'public, s-maxage=31536000, max-age=15552000'
  end
end
