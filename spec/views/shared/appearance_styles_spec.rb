# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'shared/_appearance_styles.html.erb', type: :view do
  let(:default_body_font) { 'Helvetica Neue, Helvetica, Arial, sans-serif;' }
  let(:default_headline_font) { 'Helvetica Neue, Helvetica, Arial, sans-serif;' }
  let(:body_font) { default_body_font }
  let(:headline_font) { default_headline_font }

  let(:appearance) do
    instance_double(
      Hyku::Forms::Admin::Appearance,
      body_font: body_font,
      headline_font: headline_font,
      font_import_body_url: "fonts.googleapis.com/css?family=#{body_font.split(':').first.tr(' ', '+')}",
      font_import_headline_url: "fonts.googleapis.com/css?family=#{headline_font.split(':').first.tr(' ', '+')}",
      font_body_family: body_font.split(':').first,
      font_headline_family: headline_font.split(':').first,
      link_color: '#2e74b2',
      link_hover_color: '#215080',
      header_and_footer_background_color: '#3c3c3c',
      header_and_footer_text_color: '#dcdcdc',
      navbar_background_color: '#000000',
      navbar_background_color_alpha: 'rgba(0, 0, 0, 0.4)',
      navbar_background_color_active: '#000000',
      navbar_link_background_color: '#3c3c3c',
      navbar_link_background_color_active: '#2a2a2a',
      navbar_link_background_hover_color: '#3c3c3c',
      navbar_link_background_hover_color_alpha: 'rgba(60, 60, 60, 0.15)',
      navbar_link_text_color: '#dcdcdc',
      navbar_link_text_hover_color: '#ffffff',
      active_tabs_background_color: '#f5f5f5',
      footer_link_color: '#ffebcd',
      footer_link_hover_color: '#ffffff',
      primary_button_background_color: '#2e74b2',
      primary_button_text_color: '#ffffff',
      primary_button_border_color: '#2e74b2',
      primary_button_hover_color: '#215080',
      primary_button_hover_background_color: '#215080',
      primary_button_hover_border_color: '#215080',
      primary_button_focus_background_color: '#2e74b2',
      primary_button_focus_border_color: '#2e74b2',
      default_button_background_color: '#ffffff',
      default_button_border_color: '#cccccc',
      default_button_text_color: '#333333',
      default_button_hover_background_color: '#e6e6e6',
      default_button_hover_border_color: '#adadad',
      default_button_active_background_color: '#e6e6e6',
      default_button_active_border_color: '#adadad',
      default_button_focus_background_color: '#e6e6e6',
      default_button_focus_border_color: '#999999',
      header_background_border_color: '#3c3c3c',
      facet_panel_background_color: '#f5f5f5',
      facet_panel_text_color: '#333333',
      facet_panel_border_color: '#bebebe',
      collection_banner_text_color: '#000000',
      custom_css_block: ''
    )
  end

  let(:home_page_theme) { 'default_home' }
  let(:show_page_theme) { 'default_show' }

  before do
    allow(Hyku::Forms::Admin::Appearance).to receive(:new).and_return(appearance)
    without_partial_double_verification do
      allow(view).to receive(:home_page_theme).and_return(home_page_theme)
      allow(view).to receive(:show_page_theme).and_return(show_page_theme)
      allow(view).to receive(:theme_luminance).and_return(0.04)
      allow(view).to receive(:theme_readable_ink).and_return('#ffffff')
      allow(view).to receive(:theme_brand_mix).and_return(60)
      allow(view).to receive(:theme_brand_mix_on).and_return(60)
      allow(view).to receive(:theme_ground_for).and_return('#2b2b2b')
    end
  end

  describe 'Google Fonts import guards' do
    context 'when both fonts are non-default Google Fonts' do
      let(:body_font) { 'Open Sans' }
      let(:headline_font) { 'Playfair Display' }

      before { render }

      it 'imports both fonts' do
        expect(rendered).to include('family=Open+Sans')
        expect(rendered).to include('family=Playfair+Display')
      end
    end

    context 'when body font is default Helvetica but headline font is a Google Font' do
      let(:headline_font) { 'Playfair Display' }

      before { render }

      it 'imports the headline font' do
        expect(rendered).to include('family=Playfair+Display')
      end

      it 'does not import the body font' do
        expect(rendered).not_to include('family=Helvetica')
      end
    end

    context 'when headline font is default Helvetica but body font is a Google Font' do
      let(:body_font) { 'Droid Sans' }

      before { render }

      it 'imports the body font' do
        expect(rendered).to include('family=Droid+Sans')
      end

      it 'does not import the headline font' do
        imports = rendered.scan(/@import url/)
        expect(imports.size).to eq(1)
      end
    end

    context 'when both fonts are default Helvetica' do
      before { render }

      it 'imports neither font' do
        expect(rendered).not_to include('@import url')
      end
    end
  end

  describe 'heading font-family rule' do
    let(:headline_font) { 'Playfair Display' }

    before { render }

    it 'applies the headline font to h1 through h6' do
      expect(rendered).to include('body.public-facing h1')
      expect(rendered).to include('body.public-facing h6')
      expect(rendered).to match(/body\.public-facing h6 \{ font-family: Playfair Display !important/)
    end
  end

  describe 'practice research theme' do
    let(:home_page_theme) { 'practice_research' }

    context 'with custom fonts' do
      let(:headline_font) { 'Vollkorn' }
      let(:body_font) { 'Source Sans Pro' }

      before { render }

      it 'sets --pr-serif to the admin headline font' do
        expect(rendered).to match(/--pr-serif:\s*Vollkorn/)
      end

      it 'sets --pr-sans to the admin body font' do
        expect(rendered).to match(/--pr-sans:\s*Source Sans Pro/)
      end
    end

    context 'with default Helvetica fonts' do
      before { render }

      it 'falls back to Georgia for --pr-serif' do
        expect(rendered).to match(/--pr-serif:\s*Georgia/)
      end

      it 'falls back to Helvetica Neue for --pr-sans' do
        expect(rendered).to match(/--pr-sans:\s*Helvetica Neue/)
      end
    end
  end

  describe 'digital collection theme colors' do
    let(:home_page_theme) { 'digital_collection' }
    let(:link_color) { '#2a6aa3' }
    let(:chrome) { '#3c3c3c' }
    let(:chrome_text) { '#dcdcdc' }
    let(:footer_link) { '#ffebcd' }
    let(:button_edge) { '#cccccc' }

    def variable(name)
      rendered[/--dc-#{name}:\s*([^;]+);/, 1]
    end

    before do
      allow(appearance).to receive_messages(
        link_color: link_color,
        link_hover_color: '#215480',
        header_and_footer_background_color: chrome,
        header_and_footer_text_color: chrome_text,
        footer_link_color: footer_link,
        default_button_border_color: button_edge
      )
      without_partial_double_verification do
        %i[theme_luminance theme_readable_ink theme_brand_mix theme_brand_mix_on theme_ground_for].each do |name|
          allow(view).to receive(name).and_call_original
        end
      end
      render
    end

    it 'emits the 8px radius' do
      expect(variable('radius')).to eq('8px')
    end

    it 'emits the on-dark and visited link colors for the default link' do
      expect(variable('link-on-dark')).to eq('#9cc3e5')
      expect(variable('link-visited')).to eq('#5b2aa3')
      expect(variable('link-visited-on-dark')).to eq('#c6b4df')
    end

    it 'emits status colors and their tints' do
      %w[info success danger].each do |status|
        expect(variable(status)).to match(/\A#\h{6}\z/)
        expect(variable("#{status}-on-dark")).to match(/\A#\h{6}\z/)
        expect(variable("#{status}-tint")).to match(/\A#\h{6}\z/)
      end
    end

    it 'keeps the admin button border as entered, even under 3:1' do
      expect(variable('button-edge')).to eq('#cccccc')
    end

    context 'with a link color under 4.5:1 on white' do
      let(:link_color) { '#4f7cac' }

      it 'keeps the admin link as entered' do
        expect(variable('link')).to eq('#4f7cac')
        expect(variable('accent')).to eq('#4f7cac')
      end

      it 'still builds readable visited and info colors from it' do
        expect(view.theme_contrast(variable('link-visited'), '#ffffff')).to be >= 4.5
        expect(view.theme_contrast(variable('info'), '#ffffff')).to be >= 4.5
      end
    end

    context 'with a light header and footer' do
      let(:chrome) { '#f5f5f5' }

      it 'keeps the admin ink and footer link as entered' do
        expect(variable('chrome')).to eq('#f5f5f5')
        expect(variable('chrome-ink')).to eq('#dcdcdc')
        expect(variable('footer-link')).to eq('#ffebcd')
      end
    end
  end

  { 'heritage' => 'hrt', 'screening_room' => 'scr', 'reference' => 'ref', 'digital_collection' => 'dc' }.each do |theme, prefix|
    describe "#{theme} theme CSS custom properties" do
      let(:home_page_theme) { theme }
      let(:headline_font) { 'Cardo' }
      let(:body_font) { 'Droid Sans' }

      before { render }

      it "sets --#{prefix}-serif to the admin headline font" do
        expect(rendered).to match(/--#{prefix}-serif:\s*Cardo/)
      end

      it "sets --#{prefix}-sans to the admin body font" do
        expect(rendered).to match(/--#{prefix}-sans:\s*Droid Sans/)
      end
    end
  end
end
