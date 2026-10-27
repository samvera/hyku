# frozen_string_literal: true

RSpec.describe "themes/institutional_repository/hyrax/homepage/_ir_homepage_stats.html.erb", type: :view do
  let(:field) { 'resource_type_label_sim' }
  let(:counts) { ['Pink Pajamas', 4, 'Article', 2, 'Audio', 0] }
  let(:page) { Capybara.string(rendered) }

  before do
    view.lookup_context.prefixes.prepend('themes/institutional_repository/hyrax/homepage')
    allow(view).to receive(:main_app).and_return(main_app)
    assign(:ir_counts_field, field)
    assign(:ir_counts, Blacklight::Solr::Response.new({ 'facet_counts' => { 'facet_fields' => { field => counts } } }, {}))
    render
  end

  it 'shows each resource type by the facet the controller queried, linking that facet' do
    expect(page).to have_link(href: %r{/catalog\?f%5Bresource_type_label_sim%5D%5B%5D=Pink\+Pajamas})
    expect(page).to have_css('h5', text: 'Pink Pajamas')
    expect(page).to have_content('4')
  end

  it 'lists the known resource types first' do
    expect(page.all('h5').map(&:text)).to eq ['Article', 'Pink Pajamas']
  end

  it 'gives a resource type without its own icon the default one' do
    expect(page).to have_css('a[href*="Pink"] i.fa-file-o')
    expect(page).to have_css('a[href*="Article"] i.fa-file-text-o')
  end

  it 'leaves out a resource type with no works' do
    expect(page).to have_no_css('h5', text: 'Audio')
  end

  context 'with an OER type' do
    let(:counts) { ['MovingImage', 1] }

    it 'gives it its own icon' do
      expect(page).to have_css('a[href*="MovingImage"] i.fa-file-video-o')
    end
  end

  context 'when no resource type has works' do
    let(:counts) { ['Audio', 0] }

    it 'shows nothing' do
      expect(rendered.strip).to be_empty
    end
  end

  context 'when more resource types have works than fit in a row' do
    let(:counts) { (1..7).flat_map { |n| ["Type #{n}", n] } }

    it 'uses the slider' do
      expect(page).to have_css('.institutional-repository-carousel h6', count: 7)
    end
  end
end
