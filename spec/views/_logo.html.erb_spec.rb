# frozen_string_literal: true

RSpec.describe '_logo.html.erb', type: :view do
  before do
    allow(view).to receive(:logo_image).and_return('/uploads/site/logo.png')
    allow(view).to receive(:application_name).and_return('Ellison State University')
    allow(controller).to receive(:controller_name).and_return('homepage')
  end

  context 'when the logo alt text content block is set' do
    before do
      allow(view).to receive(:block_for).with(name: 'logo_image_text').and_return('Ellison logo')
      render partial: 'logo'
    end

    it 'renders the logo image with the configured alt text' do
      expect(rendered).to have_css("img[alt='Ellison logo']")
    end
  end

  context 'when the logo alt text content block is not set' do
    before do
      allow(view).to receive(:block_for).with(name: 'logo_image_text').and_return(nil)
      render partial: 'logo'
    end

    it 'falls back to the application name for alt text' do
      expect(rendered).to have_css("img[alt='Ellison State University']")
    end

    it 'never renders a false or missing alt attribute' do
      expect(rendered).not_to include('alt_text')
      expect(rendered).not_to have_css("img[alt='false']")
      expect(rendered).not_to have_css('img:not([alt])')
    end
  end
end
