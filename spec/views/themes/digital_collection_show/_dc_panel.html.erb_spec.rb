# frozen_string_literal: true

RSpec.describe 'themes/digital_collection_show/hyrax/base/_dc_panel.html.erb', type: :view do
  let(:locals) { { modifier: 'dc-items', label_id: 'dc-items-label', label: 'Items' } }
  let(:panel) { Capybara.string(view.render(layout: 'themes/digital_collection_show/hyrax/base/dc_panel', locals:) { 'Panel body' }) }

  it 'labels the panel by its head' do
    expect(panel).to have_css("section.dc-panel.dc-items[aria-labelledby='dc-items-label']")
    expect(panel).to have_css('.dc-panel-head > h2.dc-panel-label#dc-items-label', text: 'Items')
    expect(panel).to have_css('section', text: 'Panel body')
  end

  it 'leaves out the count, the empty message and the section id unless given' do
    expect(panel).to have_no_css('.dc-panel-count')
    expect(panel).to have_no_css('.dc-panel-empty')
    expect(panel).to have_no_css('section[id]')
  end

  context 'with a count, an empty message and a section id' do
    let(:locals) { super().merge(count: 12, empty: 'This work has no items.', section_id: 'dc-items') }

    it 'shows them' do
      expect(panel).to have_css('section#dc-items')
      expect(panel).to have_css('.dc-panel-head .dc-panel-count', text: '12')
      expect(panel).to have_css('p.dc-panel-empty', text: 'This work has no items.')
    end
  end
end
