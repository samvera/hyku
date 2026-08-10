# frozen_string_literal: true

RSpec.describe 'themes/practice_research_cultural/hyrax/homepage/index.html.erb', type: :view do
  # The variant owns section ORDER, not section content: it renders the
  # practice_research partials via parent fall-through in the cultural
  # emphasis (curated collections and works first). Stub the sections and
  # assert the order.
  before do
    stub_template 'hyrax/homepage/_featured_collections.html.erb' => '<div class="stub-collections"></div>',
                  'hyrax/homepage/_featured_works.html.erb' => '<div class="stub-works"></div>',
                  'hyrax/homepage/_browse.html.erb' => '<div class="stub-browse"></div>',
                  'hyrax/homepage/_recently_uploaded.html.erb' => '<div class="stub-recent"></div>',
                  'hyrax/homepage/_featured_researcher.html.erb' => '<div class="stub-researcher"></div>',
                  'hyrax/homepage/_about.html.erb' => '<div class="stub-about"></div>'
    assign(:recent_documents, [SolrDocument.new('id' => 'x')])
    assign(:presenter, double(draw_select_work_modal?: false))
    allow(view).to receive(:pr_featured_researcher?).and_return(true)

    render template: 'themes/practice_research_cultural/hyrax/homepage/index'
  end

  it 'wraps the home in the family and variant classes' do
    expect(rendered).to have_css('.pr-home.pr-home-cultural')
  end

  it 'orders sections for the cultural story: collections, works, browse, recent, about' do
    order = %w[stub-collections stub-works stub-browse stub-recent stub-about].map { |m| rendered.index(m) }
    expect(order).to eq(order.compact.sort)
    expect(order).not_to include(nil)
  end
end
