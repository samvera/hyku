# frozen_string_literal: true

RSpec.describe 'themes/digital_collection/hyrax/homepage/_dc_featured_row.html.erb', type: :view do
  let(:locals) { { url: '/concern/generic_works/1', title: 'Harbor at dusk' } }
  let(:row) { Capybara.string(view.render(layout: 'themes/digital_collection/hyrax/homepage/dc_featured_row', locals:) { '<img alt="">'.html_safe }) }

  it 'links the thumbnail and the title to the item, hiding the thumbnail link from assistive technology' do
    expect(row).to have_css("article.dc-featured-row > a.dc-featured-thumb[href='/concern/generic_works/1'][tabindex='-1'][aria-hidden='true'] img")
    expect(row).to have_css("h3.dc-featured-title a[href='/concern/generic_works/1']", text: 'Harbor at dusk')
  end

  it 'leaves out the meta line, description and badge unless given' do
    expect(row).to have_no_css('.dc-featured-meta')
    expect(row).to have_no_css('.dc-featured-desc')
    expect(row).to have_no_css('.dc-badge')
  end

  context 'with every optional part' do
    let(:locals) do
      super().merge(thumb_class: 'dc-featured-thumb-wide', link_data: { turbolinks: false },
                    meta: ['M. Rivera', '1905'], description: 'Boats in the harbor.', badge: 'Image')
    end

    it 'shows them' do
      expect(row).to have_css('a.dc-featured-thumb.dc-featured-thumb-wide[data-turbolinks="false"]')
      expect(row).to have_css('h3 a[data-turbolinks="false"]')
      expect(row).to have_css('p.dc-featured-meta', text: 'M. Rivera · 1905')
      expect(row).to have_css('p.dc-featured-desc', text: 'Boats in the harbor.')
      expect(row).to have_css('span.dc-badge', text: 'Image')
    end
  end
end
