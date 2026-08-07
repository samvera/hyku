# frozen_string_literal: true

RSpec.describe 'catalog/_index_header_list_default.html.erb', type: :view do
  let(:document) do
    SolrDocument.new('id' => 'work1',
                     'has_model_ssim' => ['GenericWork'],
                     'title_tesim' => ['Assessment of Coastal Ecosystems'],
                     'read_access_group_ssim' => ['public'],
                     'visibility_ssi' => 'open')
  end

  before do
    allow(view).to receive(:generate_work_url).and_return('/concern/generic_works/work1')
    render partial: 'catalog/index_header_list_default', locals: { document: }
  end

  it 'renders the result title at the same heading level as collection results (h3)' do
    # Collections render h3.search-result-title; works rendered h4, so a
    # works-only results page jumped h2 -> h4 (axe heading-order).
    expect(rendered).to have_css('h3.search-result-title', text: 'Assessment of Coastal Ecosystems')
    expect(rendered).not_to have_css('h4')
  end

  it 'shows the access-status badge for the work' do
    expect(rendered).to have_css('span.badge', text: t('hyrax.visibility.open.text'))
  end
end
