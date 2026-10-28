# frozen_string_literal: true

require 'rails_helper'

# Manual Test Plan: "Settings → Labels Page", "Settings → Appearance Page", "Settings → Pages Page",
# "Settings → Content Block", and "Settings → Features Page".
RSpec.describe 'Admin settings pages', type: :feature, clean: true do
  let(:admin) { create(:admin) }
  let(:image_path) { Rails.root.join('spec', 'fixtures', 'images', 'world.png') }

  before { login_as admin }

  # Manual Test Plan: "Settings → Labels Page"
  describe 'Labels' do
    # Potential duplicate: spec/features/labels_spec.rb:14 (saves the labels and shows them on the site)
    it 'saves the application name, institution name, and full institution name' do
      visit '/site/labels/edit'
      expect(page).to have_css('.card-title', text: 'General Repository Labels')

      fill_in 'Application name', with: 'Quokka Repository'
      fill_in 'Institution name', with: 'QU'
      fill_in 'Full institution name', with: 'Quokka University'
      click_button 'Save changes'

      site = Site.instance.reload
      expect(site.application_name).to eq('Quokka Repository')
      expect(site.institution_name).to eq('QU')
      expect(site.institution_name_full).to eq('Quokka University')

      expect(page).to have_content('Labels were successfully updated.')
      expect(page).to have_field('Application name', with: 'Quokka Repository')
      expect(page).to have_field('Institution name', with: 'QU')
      expect(page).to have_field('Full institution name', with: 'Quokka University')

      visit '/agreement'
      expect(page).to have_content('Quokka University (QU) requires')
    end
  end

  # Manual Test Plan: "Settings → Appearance Page"
  describe 'Appearance' do
    def styles
      page.all('style', visible: false).map { |style| style.text(:all) }.join("\n")
    end

    it 'uploads a logo and a banner image with Save changes' do
      visit '/admin/appearance'
      within('#logo_image') do
        attach_file 'admin_appearance[logo_image]', image_path
        fill_in 'Logo image alt text', with: 'Quokka logo'
        click_button 'Save changes'
      end
      visit '/admin/appearance'
      within('#banner_image') do
        attach_file 'admin_appearance[banner_image]', image_path
        fill_in 'Banner image alt text', with: 'Quokka banner'
        click_button 'Save changes'
      end

      site = Site.instance.reload
      expect(site).to be_logo_image
      expect(site).to be_banner_image
      expect(ContentBlock.block_for(name: 'logo_image_text')).to eq('Quokka logo')
      expect(ContentBlock.block_for(name: 'banner_image_text')).to eq('Quokka banner')

      visit '/'
      expect(page).to have_css("a#logo img[src^='#{site.logo_image.url}']")
      expect(find('.background-container')[:style]).to include(site.banner_image.url)
      expect(find('.background-container')[:title]).to eq('Quokka banner')
    end

    it 'uploads default collection and work images with Save changes' do
      visit '/admin/appearance'
      within('#default_images') do
        attach_file 'admin_appearance[default_collection_image]', image_path
        fill_in 'Default collection image alt text', with: 'Default collection art'
        attach_file 'admin_appearance[default_work_image]', image_path
        fill_in 'Default work image alt text', with: 'Default work art'
        click_button 'Save changes'
      end

      site = Site.instance.reload
      expect(site).to be_default_collection_image
      expect(site).to be_default_work_image
      within('#default_images') do
        expect(page).to have_css("img[alt='Default collection art'][src='#{site.default_collection_image.url}']")
        expect(page).to have_css("img[alt='Default work art'][src='#{site.default_work_image.url}']")
      end
    end

    it 'saves a changed color with Save changes (Apply Changes) and applies it to the site' do
      visit '/admin/appearance'
      within('#color') do
        fill_in 'admin_appearance[link_color]', with: '#008080'
        click_button 'Apply Changes'
      end

      expect(ContentBlock.block_for(name: 'link_color')).to eq('#008080')
      visit '/admin/appearance'
      expect(find_field('admin_appearance[link_color]').value).to eq('#008080')

      visit '/'
      expect(styles).to include('color: #008080;')
    end

    it 'saves the body and headline fonts with Save changes and applies them to the site' do
      visit '/admin/appearance'
      within('#font') do
        fill_in 'admin_appearance[body_font]', with: 'Lato:400'
        fill_in 'admin_appearance[headline_font]', with: 'Roboto Slab:700'
        click_button 'Save changes'
      end

      expect(ContentBlock.block_for(name: 'body_font')).to eq('Lato:400')
      expect(ContentBlock.block_for(name: 'headline_font')).to eq('Roboto Slab:700')

      visit '/'
      expect(styles).to include('body.public-facing { font-family: Lato !important; }')
      expect(styles).to include('font-family: Roboto Slab !important;')
      expect(styles).to include('@import url(//fonts.googleapis.com/css?family=Lato:400);')
      expect(styles).to include('@import url(//fonts.googleapis.com/css?family=Roboto+Slab:700);')
    end

    it 'imports a changed headline font even when the body font stays the default' do
      visit '/admin/appearance'
      within('#font') do
        fill_in 'admin_appearance[headline_font]', with: 'Roboto Slab:700'
        click_button 'Save changes'
      end

      visit '/'
      expect(styles).to include('font-family: Roboto Slab !important;')
      expect(styles).to include('@import url(//fonts.googleapis.com/css?family=Roboto+Slab:700);')
    end

    it 'saves custom CSS with Save changes and serves it on the site' do
      visit '/admin/appearance'
      within('#css') do
        fill_in 'Add Custom CSS Below', with: '.navbar-brand { letter-spacing: 1px; }'
        click_button 'Save changes'
      end

      expect(ContentBlock.block_for(name: 'custom_css_block')).to eq('.navbar-brand { letter-spacing: 1px; }')
      visit '/'
      expect(styles).to include('.navbar-brand { letter-spacing: 1px; }')
    end

    context 'with JavaScript', js: true do
      def input_value(name)
        page.evaluate_script("document.querySelector(\"input[name='admin_appearance[#{name}]']\").value")
      end

      def set_input_value(name, value)
        page.execute_script("document.querySelector(\"input[name='admin_appearance[#{name}]']\").value = '#{value}'")
      end

      it 'has a color picker and a Restore Default button per element, plus Restore All Defaults' do
        visit '/admin/appearance'
        click_link 'Colors'

        defaults = Hyku::Forms::Admin::Appearance.default_colors
        within('#color') do
          expect(page).to have_css("input[type='color']", count: defaults.size)
          expect(page).to have_css('a.restore-default-color', text: 'Restore Default', count: defaults.size)
          defaults.each_key do |color_name|
            expect(page).to have_css("input[type='color'][name='admin_appearance[#{color_name}]']")
            expect(page).to have_css("a.restore-default-color[data-default-target='#{color_name}']")
          end
        end

        teal = '#008080'
        fuchsia = '#ff00ff'
        set_input_value('link_color', teal)
        set_input_value('navbar_background_color', fuchsia)
        find("a.restore-default-color[data-default-target='link_color']").click
        expect(input_value('link_color')).to eq(defaults['link_color'])
        # Restoring one color leaves the others alone.
        expect(input_value('navbar_background_color')).to eq(fuchsia)

        set_input_value('link_color', teal)
        within('#color') { click_link 'Restore All Defaults' }
        defaults.each do |color_name, hex|
          expect(input_value(color_name)).to eq(hex)
        end
      end

      it 'has body and headline font dropdowns with Restore Default buttons, plus Restore All Defaults' do
        visit '/admin/appearance'
        click_link 'Fonts'

        # The Restore Default script (fonts.js) drops the trailing semicolon from the form's defaults.
        defaults = Hyku::Forms::Admin::Appearance.default_fonts.transform_values { |font| font.delete(';') }
        within('#font') do
          expect(page).to have_css('label', text: 'Select Body Font')
          expect(page).to have_css('label', text: 'Select Header Font')
          # The fontselect plugin turns each font input into a dropdown.
          expect(page).to have_css('.font-select', count: 2)
          expect(page).to have_css("a.restore-default-font[data-default-target='body_font']", text: 'Restore Default')
          expect(page).to have_css("a.restore-default-font[data-default-target='headline_font']", text: 'Restore Default')
        end

        set_input_value('body_font', 'Lato:400')
        set_input_value('headline_font', 'Roboto:700')
        find("a.restore-default-font[data-default-target='body_font']").click
        expect(input_value('body_font')).to eq(defaults['body_font'])
        expect(input_value('headline_font')).to eq('Roboto:700')

        find("a.restore-default-font[data-default-target='headline_font']").click
        expect(input_value('headline_font')).to eq(defaults['headline_font'])

        set_input_value('body_font', 'Lato:400')
        set_input_value('headline_font', 'Roboto:700')
        within('#font') { click_link 'Restore All Defaults' }
        expect(input_value('body_font')).to eq(defaults['body_font'])
        expect(input_value('headline_font')).to eq(defaults['headline_font'])
      end
    end
  end

  # Manual Test Plan: "Settings → Pages Page"
  describe 'Pages' do
    let(:pages) do
      { 'about' => ['About Page', '/about'], 'help' => ['Help Page', '/help'],
        'agreement' => ['Deposit Agreement', '/agreement'], 'terms' => ['Terms of Use', '/terms'] }
    end

    it 'saves the content of each static page and shows it on the public page' do
      pages.each do |key, (tab_label, public_path)|
        visit '/pages/edit'
        expect(page).to have_link(tab_label, href: "##{key}")
        within("##{key}") do
          fill_in "content_block_#{key}", with: "<p>Quokka #{key} content</p>"
          click_button 'Save changes'
        end

        expect(ContentBlock.for(key.to_sym).value).to eq("<p>Quokka #{key} content</p>")
        visit public_path
        expect(page).to have_content("Quokka #{key} content")
        (pages.keys - [key]).each { |other| expect(page).not_to have_content("Quokka #{other} content") }
      end
    end

    it 'cancels changes and returns to the Pages form' do
      visit '/pages/edit'
      within('#about') { fill_in 'content_block_about', with: '<p>Discarded about text</p>' }
      # Remove this comment and the `pending` call to re-enable this test when issue #3420 is fixed.
      # KNOWN APPLICATION ISSUE: Cancel on the Pages form links to Manage Admin Sets instead of back to the Pages form (Hyrax links edit_pages_path). Fix goes in app/views/hyrax/pages/_form.html.erb.
      pending('Pages Cancel links to hyrax.admin_admin_sets_path instead of hyrax.edit_pages_path')
      within('#about') { click_link 'Cancel' }

      expect(page).to have_current_path(%r{\A/pages/edit})
      expect(ContentBlock.for(:about).value).not_to eq('<p>Discarded about text</p>')
    end

    it 'edits each page in a WYSIWYG editor', js: true do
      visit '/pages/edit'

      pages.each do |key, (tab_label, _)|
        click_link tab_label
        within("##{key}") { expect(page).to have_css('.tox-tinymce') }
      end

      click_link 'About Page'
      within('#about') do
        within_frame(find('.tox-edit-area iframe')) { find('body').set('Typed in the about editor') }
        click_button 'Save changes'
      end

      expect(page).to have_content('Pages updated.')
      expect(ContentBlock.for(:about).value).to include('Typed in the about editor')
    end
  end

  # Manual Test Plan: "Settings → Content Block"
  describe 'Content Block' do
    let(:blocks) do
      { 'announcement' => ['Announcement Text', '#announcement_text'], 'marketing' => ['Marketing Text', '#marketing'],
        'home_text' => ['Home Page Text', '#home_text'], 'researcher' => ['Featured Researcher', '#researcher'] }
    end

    it 'saves each content block and shows it on the homepage' do
      blocks.each do |key, (tab_label, pane)|
        visit '/content_blocks/edit'
        expect(page).to have_link(tab_label, href: pane)
        within(pane) do
          fill_in "content_block_#{key}", with: "<p>Quokka #{key} block</p>"
          click_button 'Save changes'
        end
        expect(page).to have_content('Content blocks updated.')
        expect(ContentBlock.for(key.to_sym).value).to eq("<p>Quokka #{key} block</p>")
      end

      visit '/'
      %w[announcement marketing researcher].each { |key| expect(page).to have_content("Quokka #{key} block") }
      # Home Page Text only shows on home themes that use it (not the default theme).
      expect(page).not_to have_content('Quokka home_text block')
      # Home themes resolve through the current account's site (see spec/features/community_theme_spec.rb).
      Site.instance.update!(home_theme: 'community')
      account = create(:account_with_public_schema)
      account.sites << Site.instance
      allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(account)
      visit '/'
      expect(page).to have_css('body.community')
      expect(page).to have_content('Quokka home_text block')
    end

    it 'cancels changes and returns to the Content Blocks form' do
      visit '/content_blocks/edit'
      within('#announcement_text') { fill_in 'content_block_announcement', with: '<p>Discarded announcement</p>' }
      # Remove this comment and the `pending` call to re-enable this test when issue #3420 is fixed.
      # KNOWN APPLICATION ISSUE: Content Blocks Cancel links to Manage Admin Sets, not back to the form (Hyrax: edit_content_blocks_path). Fix goes in app/views/hyrax/content_blocks/_form.html.erb.
      pending('Content Blocks Cancel links to hyrax.admin_admin_sets_path instead of hyrax.edit_content_blocks_path')
      within('#announcement_text') { click_link 'Cancel' }

      expect(page).to have_current_path(%r{\A/content_blocks/edit})
      expect(ContentBlock.for(:announcement).value).not_to eq('<p>Discarded announcement</p>')
    end

    # Potential duplicate: spec/views/hyrax/content_blocks/edit.html.erb_spec.rb:8 (renders each content block form)
    it "shows a WYSIWYG editor to change the content for each of the site's content blocks", js: true do
      visit '/content_blocks/edit'

      blocks.each_value do |tab_label, pane|
        click_link tab_label
        within(pane) { expect(page).to have_css('.tox-tinymce') }
      end
    end
  end

  # Manual Test Plan: "Settings → Features Page"
  # rack_test (not js) keeps Flipflop toggles inside the example's DB transaction, so they roll
  # back and cannot leak into other examples (why spec/features/feature_flag_spec.rb is xdescribe'd).
  describe 'Features' do
    def feature_row(feature)
      find("tr[data-feature='#{feature}']")
    end

    it 'lists each feature with On and Off controls' do
      visit '/admin/features'

      rows = page.all('tr[data-feature]')
      expect(rows.size).to eq(Flipflop::FeatureSet.current.features.size)
      rows.each do |row|
        buttons = row.all("td.toggle input[type='submit']").map(&:value)
        expect(buttons.size).to eq(2)
        # Every switch is On/Off, except the PDF viewer, labeled by its two viewers.
        expect(buttons).to eq(%w[on off]).or eq(%w[PDF.js UV])
      end
      expect(feature_row('show-featured-researcher')).to have_css('td.name', text: 'Show featured researcher')
    end

    # Potential duplicate: spec/features/feature_flag_spec.rb:84 (toggles show-featured-researcher; xdescribe'd)
    it 'turns a feature off and on, changing the site behavior' do
      visit '/'
      expect(page).to have_link('Featured Researcher', href: '#tab-col2-second')

      visit '/admin/features'
      within(feature_row('show-featured-researcher')) { click_button 'off' }

      expect(Flipflop.show_featured_researcher?).to be false
      within(feature_row('show-featured-researcher')) do
        expect(page).to have_css('.badge', text: 'disabled')
        expect(page).to have_css("input.active[value='off']")
      end
      visit '/'
      expect(page).not_to have_link('Featured Researcher', href: '#tab-col2-second')

      visit '/admin/features'
      within(feature_row('show-featured-researcher')) { click_button 'on' }

      expect(Flipflop.show_featured_researcher?).to be true
      expect(feature_row('show-featured-researcher')).to have_css('.badge', text: 'enabled')
      visit '/'
      expect(page).to have_link('Featured Researcher', href: '#tab-col2-second')
    end
  end
end
