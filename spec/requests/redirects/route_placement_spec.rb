# frozen_string_literal: true

RSpec.describe 'Redirects catch-all route placement', type: :request do
  # The redirects catch-all route must be the last application-defined route
  # in routes.rb so that every other route gets first crack at matching.
  # (Rails may append framework routes like ActiveStorage/ActionMailbox after it.)

  let(:all_routes) { Rails.application.routes.routes.to_a }
  let(:catch_all) { all_routes.find { |r| r.path.spec.to_s.include?('*alias_path') } }

  describe 'catch-all route exists and is configured correctly' do
    it 'has a catch-all route with *alias_path' do
      expect(catch_all).to be_present
    end

    it 'routes to hyrax/redirects#show' do
      expect(catch_all.defaults[:controller]).to eq('hyrax/redirects')
      expect(catch_all.defaults[:action]).to eq('show')
    end

    it 'appears after all application-defined routes' do
      catch_all_index = all_routes.index(catch_all)
      # Every route before the catch-all should be a non-glob application route
      # or an engine-mounted route — none should be the redirects catch-all.
      # Routes after it are only Rails framework routes (ActiveStorage, ActionMailbox, etc.)
      routes_after = all_routes[(catch_all_index + 1)..]
      app_routes_after = routes_after.reject do |r|
        path = r.path.spec.to_s
        path.start_with?('/rails/') || path == '/'
      end
      expect(app_routes_after).to be_empty,
        "Expected no application routes after the catch-all, but found: " \
        "#{app_routes_after.map { |r| r.path.spec.to_s }.join(', ')}"
    end
  end

  describe 'real Hyku routes take priority over the catch-all' do
    # These routes exist before the catch-all in routes.rb.
    # We verify the router recognizes them as their intended controllers,
    # not as the catch-all redirect resolver.

    it 'routes /status to status#index, not the catch-all' do
      route = Rails.application.routes.recognize_path('/status', method: :get)
      expect(route[:controller]).to eq('status')
      expect(route[:action]).to eq('index')
    end

    it 'routes /catalog to catalog#index, not the catch-all' do
      route = Rails.application.routes.recognize_path('/catalog', method: :get)
      expect(route[:controller]).to eq('catalog')
    end

    it 'routes /bookmarks to bookmarks#index, not the catch-all' do
      route = Rails.application.routes.recognize_path('/bookmarks', method: :get)
      expect(route[:controller]).to eq('bookmarks')
    end
  end
end
