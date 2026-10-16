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

  describe '#dc_account_links' do
    let(:ability) { instance_double(Ability, user_groups: []) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:current_ability).and_return(ability)
      end
      allow(Flipflop).to receive(:show_login_link?).and_return(true)
    end

    context 'on a tenant' do
      before do
        without_partial_double_verification { allow(helper).to receive(:admin_host?).and_return(false) }
      end

      it 'lists the dashboard and the notifications with the unread count' do
        labels = helper.dc_account_links(3).map(&:first)

        expect(labels).to start_with(I18n.t('hyrax.toolbar.dashboard.menu'), 'Notifications (3)')
      end

      it 'drops the count when nothing is unread' do
        expect(helper.dc_account_links(0).map(&:first)).to include('Notifications')
      end

      it 'offers log out when the login link is on' do
        expect(helper.dc_logout_link.first).to eq(I18n.t('hyrax.toolbar.profile.logout'))
      end

      it 'hides log out from non-admins when the login link is off' do
        allow(Flipflop).to receive(:show_login_link?).and_return(false)

        expect(helper.dc_logout_link).to be_nil
      end
    end

    context 'on the admin host' do
      before do
        without_partial_double_verification { allow(helper).to receive(:admin_host?).and_return(true) }
      end

      it 'lists Accounts and Users for a super admin' do
        allow(helper).to receive(:can?).with(:manage, Account).and_return(true)

        expect(helper.dc_account_links(0).map(&:first)).to eq([I18n.t('hyku.proprietor.accounts.nav'), I18n.t('hyku.proprietor.users.nav')])
        expect(helper.dc_logout_link).to be_present
      end

      it 'lists nothing but log out for anyone else' do
        allow(helper).to receive(:can?).with(:manage, Account).and_return(false)

        expect(helper.dc_account_links(0)).to be_empty
        expect(helper.dc_logout_link).to be_present
      end
    end
  end

  describe '#dc_content_block' do
    it 'renders the block and turns its h1 headings into h2' do
      html = helper.dc_content_block(ContentBlock.new(name: 'home_text', value: '<h1>Welcome</h1><p>Hello</p>'), id: 'x')

      expect(Capybara.string(html)).to have_css('div#x > h2', text: 'Welcome')
      expect(Capybara.string(html)).to have_no_css('h1')
    end

    it 'renders nothing for an empty block' do
      expect(helper.dc_content_block(ContentBlock.new(name: 'home_text', value: ''))).to be_nil
    end
  end

  describe '#dc_hero_headline' do
    it 'marks text with no heading as the level one heading' do
      html = Capybara.string(helper.dc_hero_headline(ContentBlock.new(name: 'marketing_text', value: '<p>Explore</p>')))

      expect(html).to have_css('div.dc-hero-headline[role="heading"][aria-level="1"] p', text: 'Explore')
    end

    it 'promotes the first heading to h1 and demotes any other h1' do
      html = Capybara.string(helper.dc_hero_headline(ContentBlock.new(name: 'marketing_text', value: '<h3>Maps</h3><h1>More</h1>')))

      expect(html).to have_css('div.dc-hero-headline:not([role]) > h1', text: 'Maps')
      expect(html).to have_css('div.dc-hero-headline > h2', text: 'More')
      expect(html).to have_css('h1', count: 1)
    end
  end

  describe '#dc_thumb_placeholder_class' do
    it 'marks a missing or stock thumbnail as a placeholder' do
      expect(helper.dc_thumb_placeholder_class({})).to eq('dc-thumb-placeholder')
      expect(helper.dc_thumb_placeholder_class('thumbnail_path_ss' => '/assets/default-abc.png')).to eq('dc-thumb-placeholder')
    end

    it 'leaves a real thumbnail alone' do
      expect(helper.dc_thumb_placeholder_class('thumbnail_path_ss' => '/downloads/abc?file=thumbnail')).to be_nil
    end
  end

  describe '#dc_banner_src' do
    let(:collection_id) { 'abc123' }
    let(:local_path) { Rails.root.join('tmp', 'branding', collection_id, 'banner', 'harbor.jpg').to_s }

    before do
      without_partial_double_verification { allow(helper).to receive(:banner_image).and_return('/site-banner.jpg') }
    end

    after { FileUtils.rm_rf(Rails.root.join('tmp', 'branding')) }

    it 'uses the site banner when the collection has no banner' do
      expect(helper.dc_banner_src(collection_id)).to eq('/site-banner.jpg')
    end

    it 'uses the site banner when the banner file is missing' do
      CollectionBrandingInfo.create!(collection_id:, role: 'banner', local_path:, filename: 'harbor.jpg')

      expect(helper.dc_banner_src(collection_id)).to eq('/site-banner.jpg')
    end

    it 'uses the collection banner when its file exists' do
      FileUtils.mkdir_p(File.dirname(local_path))
      FileUtils.touch(local_path)
      CollectionBrandingInfo.create!(collection_id:, role: 'banner', local_path:, filename: 'harbor.jpg')

      expect(helper.dc_banner_src(collection_id)).to eq("/branding/#{collection_id}/banner/harbor.jpg")
    end
  end

  describe '#dc_tall_banner?' do
    def branding(path)
      CollectionBrandingInfo.new(collection_id: 'abc123', role: 'banner', local_path: path, filename: File.basename(path.to_s))
    end

    it 'treats a portrait banner as tall' do
      expect(helper.dc_tall_banner?(branding(Rails.root.join('spec', 'fixtures', 'images', 'nypl-hydra-of-lerna.jpg').to_s))).to be(true)
    end

    it 'leaves a landscape banner full-bleed' do
      path = Rails.root.join('spec', 'fixtures', 'images', 'nypl-hydra-of-lerna.jpg').to_s
      allow(MiniMagick::Image).to receive(:new).with(path).and_return(instance_double(MiniMagick::Image, dimensions: [1600, 600]))

      expect(helper.dc_tall_banner?(branding(path))).to be(false)
    end

    it 'is false without a banner file' do
      expect(helper.dc_tall_banner?(nil)).to be(false)
      expect(helper.dc_tall_banner?(branding(Rails.root.join('tmp', 'missing.jpg').to_s))).to be(false)
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

  describe 'theme colors' do
    let(:white) { '#ffffff' }
    let(:hero_ground) { '#2c2b29' }
    let(:light_plate_worst) { helper.dc_mix('#000000', '#ffffff', 0.92) }
    let(:dark_plate_worst) { helper.dc_mix('#ffffff', '#141312', 0.78) }

    links = {
      'default' => '#2a6aa3',
      'red' => '#b3261e',
      'green' => '#2e7d32',
      'near-limit' => '#4274a8',
      'too light' => '#4f7cac',
      'dark' => '#1a1a1a'
    }

    describe '#dc_darken_until' do
      it 'darkens a color until it clears 4.5:1 on white, keeping its hue' do
        checked = helper.dc_darken_until('#4f7cac', white, 4.5)

        expect(helper.theme_contrast('#4f7cac', white)).to be < 4.5
        expect(helper.theme_contrast(checked, white)).to be >= 4.5
        expect(helper.dc_hue_shift(checked, '#4f7cac')).to be < 1
      end

      it 'keeps a color that already passes' do
        expect(helper.dc_darken_until('#2a6aa3', white, 4.5)).to eq('#2a6aa3')
      end
    end

    describe '#dc_lighten_until' do
      it 'gives the default on-dark link from the default admin link' do
        expect(helper.dc_lighten_until('#2a6aa3', dark_plate_worst, 5)).to eq('#9cc3e5')
      end

      it 'keeps the hue while lightening' do
        lifted = helper.dc_lighten_until('#b3261e', dark_plate_worst, 5)

        expect(helper.dc_hue_shift(lifted, '#b3261e')).to be < 2
        expect(helper.theme_contrast(lifted, dark_plate_worst)).to be >= 5
      end
    end

    describe '#dc_status_color' do
      links.each do |name, link|
        context "with a #{name} link color" do
          let(:checked) { helper.dc_darken_until(link, white, 4.5) }

          %i[danger success].each do |status|
            it "keeps #{status} within 20 degrees of its base hue and at 4.5:1 on white" do
              color = helper.dc_status_color(status, checked)
              base = DigitalCollectionHelper::DC_STATUS_BASE.fetch(status)

              expect(helper.dc_hue_shift(color, base)).to be <= 20
              expect(helper.theme_contrast(color, white)).to be >= 4.5
            end

            it "keeps the on-dark #{status} at 4.5:1 on the hero ground" do
              color = helper.dc_on_dark(helper.dc_status_color(status, checked), hero_ground)

              expect(helper.theme_contrast(color, hero_ground)).to be >= 4.5
            end
          end
        end
      end

      it 'drops the blend for danger when the link is itself red' do
        expect(helper.dc_status_color(:danger, '#b3261e')).to eq(helper.dc_darken_until('#b4433c', white, 4.5))
      end

      it 'drops the blend for success when the link is itself green' do
        expect(helper.dc_status_color(:success, '#2e7d32')).to eq(helper.dc_darken_until('#3c763d', white, 4.5))
      end
    end

    describe '#dc_visited_color' do
      it 'gives the spec values for the default link' do
        visited = helper.dc_visited_color('#2a6aa3', light_plate_worst)

        expect(visited).to eq('#5b2aa3')
        expect(helper.dc_on_dark(visited, dark_plate_worst)).to eq('#c6b4df')
      end

      links.each do |name, link|
        it "never reads as red or green and clears both plates for a #{name} link" do
          visited = helper.dc_visited_color(helper.dc_darken_until(link, white, 4.5), light_plate_worst)
          on_dark = helper.dc_on_dark(visited, dark_plate_worst)

          expect(helper.dc_reddish?(visited) || helper.dc_greenish?(visited)).to be(false)
          expect(helper.theme_contrast(visited, light_plate_worst)).to be >= 4.5
          expect(helper.theme_contrast(on_dark, dark_plate_worst)).to be >= 4.5
        end
      end
    end
  end

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

  describe 'creator and summary hooks' do
    let(:document) { SolrDocument.new('id' => 'w1', 'has_model_ssim' => ['GenericWork'], 'creator_tesim' => ['Ada Lovelace'], 'description_tesim' => ['A short summary.']) }
    let(:presenter) { Hyrax::WorkShowPresenter.new(document, Ability.new(nil), nil) }

    before { without_partial_double_verification { allow(helper).to receive(:current_user).and_return(nil) } }

    it "reads a work page's creator and summary when the profile shows them" do
      allow(helper).to receive(:dc_profile_shows?).and_return(true)

      expect(helper.dc_creator_names(presenter)).to eq(['Ada Lovelace'])
      expect(helper.dc_summary(presenter)).to eq(['A short summary.'])
    end

    it 'leaves them out when the profile hides them' do
      allow(helper).to receive(:dc_profile_shows?).and_return(false)

      expect(helper.dc_creator_names(presenter)).to be_empty
      expect(helper.dc_summary(presenter)).to be_empty
    end

    it "reads a search result's creator only when the results show it" do
      allow(helper).to receive(:dc_result_field_shown?).with(document, 'creator_tesim').and_return(true, false)

      expect(helper.dc_creator_names(document)).to eq(['Ada Lovelace'])
      expect(helper.dc_creator_names(document)).to be_empty
    end

    it "reads a search result's summary" do
      expect(helper.dc_summary(document)).to eq(['A short summary.'])
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

  describe 'search result rows' do
    let(:document) do
      SolrDocument.new('id' => 'w1', 'has_model_ssim' => ['GenericWork'], 'title_tesim' => ['Ward'], 'creator_tesim' => ['Allen & Ginter'],
                       'date_created_tesim' => ['1887'], 'resource_type_tesim' => ['Image'], 'description_tesim' => ['One print.'],
                       'member_of_collection_ids_ssim' => ['c1'], 'member_of_collections_ssim' => ['Baseball Cards'])
    end

    def rows
      helper.dc_result_fields(document).to_h { |key, row| [key, Capybara.string(row)] }
    end

    context 'with flexible metadata' do
      let(:profile_fields) do
        { 'title_tesim' => ['Title', 'Ward'], 'keyword_tesim' => ['Keyword', '<a href="/catalog?q=cards">cards</a>'.html_safe],
          'creator_tesim' => ['Maker', 'Allen & Ginter'], 'date_created_tesim' => ['Date Created', '1887'], 'abstract_tesim' => ['Abstract', ''] }
      end

      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(true)
        presenter = instance_double(Blacklight::DocumentPresenter)
        allow(presenter).to receive(:fields_to_render) do
          profile_fields.map { |name, (_label, value)| [name, Blacklight::Configuration::IndexField.new(key: name), instance_double(Blacklight::FieldPresenter, render: value)] }
        end
        allow(helper).to receive(:document_presenter).and_return(presenter)
        allow(helper).to receive(:index_field_label) { |_doc, name| profile_fields[name].first }
        allow(helper).to receive(:markdown) { |value| value }
      end

      it "shows the profile's search result fields in its order with its labels, leaving out the title and empty values" do
        expect(rows.keys).to eq(%i[keyword creator date_created part_of])
        expect(rows[:creator]).to have_css('dt', text: 'Maker')
        expect(rows[:keyword].find('a')['href']).to eq('/catalog?q=cards')
      end

      it 'adds the Part of link after the profile fields' do
        expect(rows[:part_of].find('a', text: 'Baseball Cards')['href']).to include('/collections/c1')
      end

      it 'leaves the creator off a card when the profile keeps it out of search results' do
        profile_fields.delete('creator_tesim')

        expect(helper.dc_card_meta(document)).to eq('1887')
      end
    end

    context 'without flexible metadata' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it "shows the theme's fields with plain values" do
        expect(rows.keys).to eq(%i[creator date part_of resource_type description])
        expect(rows[:creator]).to have_css('dt', text: 'Creator')
        expect(rows[:creator]).to have_no_css('a')
      end

      it 'puts the creator and date on a card' do
        expect(helper.dc_card_meta(document)).to eq('Allen & Ginter · 1887')
      end
    end
  end

  describe 'file set details' do
    let(:presenter) do
      double('file set', depositor: '', date_uploaded: '2026-09-03', date_modified: nil, fixity_check_status: 'Passed',
                         mime_type: ['image/jpeg'], file_size: ['4404019'], width: ['6000'], height: ['4500'])
    end

    describe '#dc_file_detail_rows' do
      it 'lists the facts in plain words and skips the blank ones' do
        allow(helper).to receive(:link_to_profile).and_return('')

        expect(helper.dc_file_detail_rows(presenter)).to eq([['Date uploaded', 'September 3, 2026'], ['Fixity check', 'Passed'],
                                                             ['File format', 'image/jpeg'], ['File size', '4.2 MB'],
                                                             ['Dimensions', '6000 × 4500 px']])
      end
    end

    describe '#dc_long_date' do
      it "writes a date or a time in the reader's date format" do
        expect(I18n.with_locale(:de) { helper.dc_long_date('2026-09-03') }).to eq('3. September 2026')
        expect(helper.dc_long_date(Time.zone.local(2026, 9, 3, 15))).to eq('September 3, 2026')
      end

      it 'gives nothing for a blank or unreadable value' do
        expect(helper.dc_long_date('')).to be_nil
        expect(helper.dc_long_date('not a date')).to be_nil
      end
    end
  end
end
