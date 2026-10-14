# frozen_string_literal: true

RSpec.describe 'hyrax/base/iiif_viewers/_ramp.html.erb', type: :view do
  let(:presenter) { double('WorkShowPresenter', iiif_viewer: :ramp) }

  before do
    allow(view).to receive(:iiif_viewer_base_url).with(:ramp).and_return('http://test.host/ramp/ramp.html')
    allow(view.main_app).to receive(:polymorphic_url).and_return('http://test.host/concern/generic_works/99/manifest')

    render 'hyrax/base/iiif_viewers/ramp', presenter:
  end

  it 'wraps the player in the class viewer.scss sizes it by' do
    expect(rendered).to have_selector('.viewer-wrapper.ramp-viewer-wrapper')
  end

  it 'points the iframe at the ramp asset with the work manifest' do
    src = Nokogiri::HTML.fragment(rendered).at_css('iframe')['src']

    expect(src).to start_with('http://test.host/ramp/ramp.html')
    expect(src).to include('manifest=http://test.host/concern/generic_works/99/manifest')
  end
end
