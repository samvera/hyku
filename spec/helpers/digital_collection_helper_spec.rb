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
end
