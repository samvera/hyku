# frozen_string_literal: true

RSpec.describe 'themes/cultural_repository/hyrax/homepage/_recent_document.html.erb', type: :view do
  let(:recent_document) do
    SolrDocument.new('id' => 'abc123',
                     'has_model_ssim' => ['GenericWork'],
                     'title_tesim' => ['Harbor at dusk'],
                     'thumbnail_alt_text_tesim' => ['Photograph of the harbor at dusk'])
  end

  before do
    allow(view).to receive(:generate_work_url).and_return('/concern/generic_works/abc123')
    # Echo the options render_thumbnail_tag receives so the rendered markup
    # shows exactly what the partial passed through.
    allow(view).to receive(:render_thumbnail_tag) do |_doc, image_options, _url_options|
      # rubocop:disable Rails/OutputSafety - fixture markup echoing the options the partial passed
      %(<img src="thumb.png" class="#{image_options[:class]}" #{"alt=\"#{image_options[:alt]}\"" if image_options.key?(:alt)}>).html_safe
      # rubocop:enable Rails/OutputSafety
    end

    render partial: 'themes/cultural_repository/hyrax/homepage/recent_document',
           locals: { recent_document: }
  end

  it 'is a list item (the collection renders inside an ol)' do
    expect(rendered).to have_css('li.recently-uploaded')
    expect(rendered).not_to have_css('div.recently-uploaded')
  end

  it 'gives the thumbnail its alt text' do
    expect(rendered).to have_css("img[alt='Photograph of the harbor at dusk']")
  end

  it 'gives the thumbnail link a discernible name via the image alt' do
    expect(rendered).to have_css("a > img[alt='Photograph of the harbor at dusk']")
  end
end
