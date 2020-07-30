# frozen_string_literal: true

RSpec.describe '/concern/generic_works routing' do
  it "routes to manifest" do
    expect(get: '/concern/generic_works/1234/manifest')
      .to route_to(controller: 'hyrax/generic_works', action: 'manifest', id: '1234')
  end
end
