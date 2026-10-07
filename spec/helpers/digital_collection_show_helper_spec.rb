# frozen_string_literal: true

RSpec.describe DigitalCollectionShowHelper, type: :helper do
  describe '#dc_inline_markdown' do
    it 'keeps inline formatting without a wrapping paragraph when markdown is on' do
      allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(true)

      expect(helper.dc_inline_markdown('Maps of *the* Hudson')).to eq('Maps of <em>the</em> Hudson')
    end

    it 'leaves the text as written, with markup stripped, when markdown is off' do
      allow(Flipflop).to receive(:treat_some_user_inputs_as_markdown?).and_return(false)

      expect(helper.dc_inline_markdown('Maps of <script>x</script>*the* Hudson')).to eq('Maps of x*the* Hudson')
    end
  end

  describe '#dc_collection_metadata_rows' do
    let(:document) do
      SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['Collection'], 'title_tesim' => ['Harbor Records'],
                       'creator_tesim' => ['Harbor Museum'], 'resource_type_tesim' => ['Map'])
    end
    let(:presenter) { Hyrax::CollectionPresenter.new(document, Ability.new(nil), nil) }
    let(:definitions) do
      { title: { 'html_dl' => true }, creator: { 'render_as' => 'linked', 'html_dl' => true },
        resource_type: { 'render_as' => 'faceted', 'html_dl' => true }, keyword: { 'render_as' => 'linked', 'html_dl' => true },
        rights_notes: { 'html_dl' => true, 'show_page' => false } }
    end

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      allow(helper).to receive(:dc_collection_view_definitions).and_return(definitions)
    end

    it "renders each field with the profile's render_as, leaving out the title and empty or hidden fields" do
      rows = Capybara.string(helper.safe_join(helper.dc_collection_metadata_rows(presenter)))

      expect(rows).to have_css('dt', count: 2)
      expect(rows).to have_no_css('dt', text: 'Title')
      expect(rows.find('a', text: 'Harbor Museum')['href']).to include('search_field=creator')
      expect(CGI.unescape(rows.find('a', text: 'Map')['href'])).to include('f[resource_type_sim][]=Map')
    end
  end

  describe '#dc_profile_shows?' do
    let(:presenter) { Hyrax::CollectionPresenter.new(SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['Collection']), Ability.new(nil), nil) }

    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      without_partial_double_verification { allow(helper).to receive(:current_user).and_return(nil) }
    end

    it 'shows a field the profile gives no view settings' do
      allow(helper).to receive(:dc_profile_view_definitions).and_return({})

      expect(helper.dc_profile_shows?(presenter, :description)).to be(true)
    end

    it 'hides a field the profile keeps off the show page or limits to admins' do
      allow(helper).to receive(:dc_profile_view_definitions).and_return(description: { 'show_page' => false }, abstract: { 'admin_only' => true })

      expect(helper.dc_profile_shows?(presenter, :description)).to be(false)
      expect(helper.dc_profile_shows?(presenter, :abstract)).to be(false)
    end
  end

  describe '#dc_external_links_in_new_tab' do
    it 'opens links to other sites in a new tab without access to this page' do
      html = helper.dc_external_links_in_new_tab('<a href="https://example.org/x" rel="license">x</a>')

      expect(Capybara.string(html)).to have_css('a[target="_blank"][rel="license noopener noreferrer"]')
    end

    it "moves Hyrax's leading icon to the end of the link and names the new tab for screen readers" do
      html = helper.dc_external_links_in_new_tab(%(<li><span class="fa fa-external-link"></span>&nbsp;<a href="https://example.org">Example</a></li>))
      link = Nokogiri::HTML::DocumentFragment.parse(html).at_css('li > a')

      expect(link.parent.element_children.map(&:name)).to eq(['a'])
      expect(link.children.to_a.last(2).map { |node| node['class'] }).to eq(['dc-external-end', 'sr-only'])
      expect(link.at_css('.dc-external-end').text).to eq('Example')
      expect(link.at_css('.dc-external-end > .dc-external-icon')['aria-hidden']).to eq('true')
      expect(link.at_css('.sr-only').text).to eq('(opens in a new tab)')
    end

    it 'moves an icon Hyrax puts at the start inside a bare link to the end' do
      html = helper.dc_external_links_in_new_tab(%(<a href="http://www.notch8.com"><span class='fa fa-external-link'></span>&nbsp;www.notch8.com</a>))
      link = Nokogiri::HTML::DocumentFragment.parse(html).at_css('a')

      expect(link.css('.fa-external-link').size).to eq(1)
      expect(link.at_css('.dc-external-end').text).to eq('www.notch8.com')
      expect(link.children.to_a.last(2).map { |node| node['class'] }).to eq(['dc-external-end', 'sr-only'])
    end

    it 'keeps the last word of a long link with the icon so the icon never wraps alone' do
      html = helper.dc_external_links_in_new_tab('<a href="https://example.org">Creative Commons 4.0 International</a>')
      link = Nokogiri::HTML::DocumentFragment.parse(html).at_css('a')

      expect(link.children.first.text).to eq('Creative Commons 4.0 ')
      expect(link.at_css('.dc-external-end').text).to eq('International')
    end

    it 'leaves links on this site, relative links and email links alone' do
      html = helper.dc_external_links_in_new_tab(%(<a href="http://#{helper.request.host}/catalog">a</a><a href="/catalog">b</a><a href="mailto:x@example.org">c</a>))

      expect(Capybara.string(html)).to have_no_css('a[target]')
    end
  end

  describe '#dc_collection_type_label' do
    let(:type) { Hyrax::CollectionType.find_or_create_default_collection_type }

    it 'translates the default collection type' do
      I18n.with_locale(:de) { expect(helper.dc_collection_type_label(type)).to eq('Benutzersammlung') }
    end

    it "keeps a name the admin gave the type, as written" do
      type.title = 'Museum Collection'

      I18n.with_locale(:de) { expect(helper.dc_collection_type_label(type)).to eq('Museum Collection') }
    end
  end

  describe '#dc_collection_meta' do
    let(:presenter) { double(creator: ['Hudson River Museum'], total_viewable_items: 24, modified_date: '2026-09-03') }

    it 'joins the creator, the item count and the last update on one line' do
      expect(helper.dc_collection_meta(presenter)).to eq('Created by Hudson River Museum · <strong>24 items</strong> · Last updated September 3, 2026')
    end

    it 'leaves out the creator when the metadata profile hides it' do
      allow(helper).to receive(:dc_profile_shows?).with(presenter, :creator).and_return(false)

      expect(helper.dc_collection_meta(presenter)).to eq('<strong>24 items</strong> · Last updated September 3, 2026')
    end

    it 'leaves out what the collection does not have' do
      allow(presenter).to receive_messages(creator: [], modified_date: nil, total_viewable_items: 1)

      expect(helper.dc_collection_meta(presenter)).to eq('<strong>1 item</strong>')
    end
  end
end
