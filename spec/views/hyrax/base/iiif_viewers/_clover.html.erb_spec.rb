# frozen_string_literal: true

RSpec.describe 'hyrax/base/iiif_viewers/_clover.html.erb', type: :view do
  let(:presenter) { double('WorkShowPresenter', iiif_viewer: :clover) }

  before do
    allow(view).to receive(:iiif_viewer_base_url).with(:clover).and_return('http://test.host/clover/clover.html')
    allow(view.main_app).to receive(:polymorphic_url).and_return('http://test.host/concern/generic_works/99/manifest')

    render 'hyrax/base/iiif_viewers/clover', presenter:
  end

  it 'wraps the player in the class _viewer.scss sizes it by' do
    expect(rendered).to have_selector('.viewer-wrapper.clover-viewer-wrapper')
  end

  it 'points the iframe at the clover asset with the work manifest' do
    src = Nokogiri::HTML.fragment(rendered).at_css('iframe')['src']

    expect(src).to start_with('http://test.host/clover/clover.html')
    expect(src).to include('manifest=http://test.host/concern/generic_works/99/manifest')
  end
end
