# frozen_string_literal: true

RSpec.describe 'themes/neutral_repository/_featured_carousel.html.erb', type: :view do
  let(:work) do
    SolrDocument.new('id' => 'work1',
                     'has_model_ssim' => ['GenericWork'],
                     'title_tesim' => ['Harbor at dusk'],
                     'thumbnail_alt_text_tesim' => ['Photograph of the harbor at dusk'])
  end
  let(:featured_work) { FeaturedWork.new(work_id: 'work1', order: 0) }

  before do
    assign(:featured_work_list, FeaturedWorkList.new.tap { |l| allow(l).to receive(:featured_works).and_return([featured_work]) })
    allow(SolrDocument).to receive(:find).with('work1').and_return(work)
    allow(view).to receive(:render_thumbnail_tag) do |_doc, image_options, _url_options|
      # rubocop:disable Rails/OutputSafety - fixture markup echoing the options the partial passed
      %(<img src="thumb.png" alt="#{image_options[:alt]}">).html_safe
      # rubocop:enable Rails/OutputSafety
    end

    render partial: 'themes/neutral_repository/featured_carousel'
  end

  it 'renders the carousel slides' do
    expect(rendered).to have_css('.carousel-inner .carousel-item')
  end

  it 'does not give the slide wrapper a listbox role' do
    # role="listbox" is an input role that requires a label and allows only
    # option children; on .carousel-inner it produces a critical
    # aria-required-children and a serious aria-input-field-name axe violation.
    # Bootstrap 4 dropped this Bootstrap 3-era pattern for exactly this reason.
    expect(rendered).not_to have_css('[role="listbox"]')
  end
end
