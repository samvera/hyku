# frozen_string_literal: true

RSpec.describe BlacklightRangeLimit::RangeFacetComponentDecorator do
  let(:controller) do
    Hyrax::HomepageController.new.tap do |c|
      c.request = ActionDispatch::TestRequest.create
      c.request.path_parameters = { controller: 'hyrax/homepage', action: 'index' }
    end
  end
  let(:search_state) { Blacklight::SearchState.new({}, CatalogController.blacklight_config, controller) }
  let(:facet_field) { double(key: 'date_range_isim', search_state:) }
  let(:component) do
    BlacklightRangeLimit::RangeFacetComponent.new(facet_field:).tap do |c|
      allow(c).to receive(:helpers).and_return(controller.helpers)
    end
  end

  it 'reproduces the bug without the decorator' do
    upstream = BlacklightRangeLimit::RangeFacetComponent.instance_method(:range_limit_url).super_method
    expect { upstream.bind_call(component, range_start: 1900, range_end: 2000) }
      .to raise_error(ActionController::UrlGenerationError, /hyrax\/homepage/)
  end

  it 'points the range_limit link at the catalog' do
    expect(component.range_limit_url(range_start: 1900, range_end: 2000))
      .to include('/catalog/range_limit').and include('range_field=date_range_isim')
  end
end
