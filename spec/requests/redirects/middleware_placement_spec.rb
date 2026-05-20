# frozen_string_literal: true

RSpec.describe 'Redirects middleware placement', type: :request do
  # The redirects resolver runs as a Rack middleware ahead of Rails
  # routing. Hyku-side verification: the middleware is in the stack at
  # all, and real Hyku routes still resolve normally for paths that
  # don't match a registered alias.

  let(:middleware_stack) { Rails.application.middleware.map(&:klass).map(&:to_s) }

  it 'has Hyrax::Redirects::Middleware in the stack' do
    expect(middleware_stack).to include('Hyrax::Redirects::Middleware')
  end

  describe 'real Hyku routes take priority over the middleware' do
    # The middleware passes through any path that isn't a registered
    # alias, so these routes resolve to their intended controllers.

    it 'routes /status to status#index' do
      route = Rails.application.routes.recognize_path('/status', method: :get)
      expect(route[:controller]).to eq('status')
      expect(route[:action]).to eq('index')
    end

    it 'routes /catalog to catalog#index' do
      route = Rails.application.routes.recognize_path('/catalog', method: :get)
      expect(route[:controller]).to eq('catalog')
    end

    it 'routes /bookmarks to bookmarks#index' do
      route = Rails.application.routes.recognize_path('/bookmarks', method: :get)
      expect(route[:controller]).to eq('bookmarks')
    end
  end
end
