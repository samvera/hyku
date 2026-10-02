# frozen_string_literal: true

RSpec.describe DigitalCollectionHelper, type: :helper do
  describe '#dc_section_head' do
    it 'renders the section title with the id the section is labelled by' do
      head = Capybara.string(helper.dc_section_head('Browse collections', id: 'dc-browse-heading'))

      expect(head).to have_css('div.dc-section-head > h2.dc-section-title#dc-browse-heading', text: 'Browse collections')
      expect(head).to have_no_css('.dc-section-eyebrow')
      expect(head).to have_no_css('a')
    end

    it 'puts the eyebrow before the title and the action after it' do
      html = helper.dc_section_head('Recently added', id: 'dc-recent-heading', eyebrow: 'New',
                                                      action: helper.link_to('View all recently added works', '/catalog', class: 'dc-section-action'))
      head = Capybara.string(html)

      expect(head).to have_css('p.dc-section-eyebrow', text: 'New')
      expect(head).to have_css('a.dc-section-action[href="/catalog"]', text: 'View all recently added works')
      expect(html.index('dc-section-eyebrow')).to be < html.index('dc-section-title')
      expect(html.index('dc-section-title')).to be < html.index('dc-section-action')
    end

    it 'renders extra head content from a block between the title and the action' do
      html = helper.dc_section_head('Browse collections', id: 'dc-browse-heading', action: helper.tag.a('All')) do
        helper.tag.div('Controls', class: 'dc-browse-controls')
      end

      expect(Capybara.string(html)).to have_css('.dc-section-head > .dc-browse-controls', text: 'Controls')
      expect(html.index('dc-browse-controls')).to be < html.index('<a>')
    end
  end

  describe '#dc_badge' do
    it 'renders a dc-badge by default' do
      expect(helper.dc_badge('Image')).to eq('<span class="dc-badge">Image</span>')
    end

    it 'takes another class for the work page chip' do
      expect(helper.dc_badge('Image', class_name: 'dc-chip')).to eq('<span class="dc-chip">Image</span>')
    end

    it 'adds a status class when given a kind' do
      expect(helper.dc_badge('Public', kind: :success)).to eq('<span class="dc-badge dc-badge-success">Public</span>')
    end
  end
end
