# frozen_string_literal: true

RSpec.describe "file routes", type: :routing do
  routes { Rails.application.routes }

  # rubocop:disable Layout/LineLength
  it 'creates a featured_collection' do
    expect(post: '/collections/7/featured_collection').to route_to(controller: 'hyrax/featured_collections', action: 'create', id: '7')
  end
  it 'removes a featured_collection' do
    expect(delete: '/collections/7/featured_collection').to route_to(controller: 'hyrax/featured_collections', action: 'destroy', id: '7')
  end

  it 'updates a list of featured collections' do
    expect(featured_collection_lists_path).to eq '/featured_collections'
    expect(post: '/featured_collections').to route_to(controller: 'hyrax/featured_collection_lists', action: 'create')
  end
  # rubocop:enable Metrics/MethodLength
end
