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
