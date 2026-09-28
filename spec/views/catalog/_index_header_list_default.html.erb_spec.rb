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
  end

  context 'with a work' do
    before { render partial: 'catalog/index_header_list_default', locals: { document: } }

    it 'renders the result title at the same heading level as collection results (h3)' do
      # Collections render h3.search-result-title; works rendered h4, so a
      # works-only results page jumped h2 -> h4 (axe heading-order).
      expect(rendered).to have_css('h3.search-result-title', text: 'Assessment of Coastal Ecosystems')
      expect(rendered).not_to have_css('h4.search-result-title')
    end

    it 'shows the access-status badge for the work' do
      expect(rendered).to have_css('span.badge', text: t('hyrax.visibility.open.text'))
    end
  end

  context 'with the configured collection class' do
    let(:document) do
      SolrDocument.new('id' => 'collection1',
                       'has_model_ssim' => [Hyrax.config.collection_model],
                       'title_tesim' => ['Coastal Survey Collection'],
                       'read_access_group_ssim' => ['public'],
                       'visibility_ssi' => 'open')
    end

    let(:badge) do
      ActionController::Base.helpers.tag.span('Collection', class: 'badge', style: 'background-color: #fff;')
    end

    before do
      allow(view).to receive(:current_ability).and_return(Ability.new(nil))
      allow(Hyrax::CollectionPresenter).to receive(:new).and_return(
        instance_double(Hyrax::CollectionPresenter, collection_type_badge: badge)
      )
      render partial: 'catalog/index_header_list_default', locals: { document: }
    end

    # Both badges render span.badge; only the collection type badge carries an
    # inline background-color, so the style is the only way to tell them apart.
    it 'shows the collection type badge rather than the access-status badge' do
      expect(rendered).to have_css('span.badge[style*="background-color"]')
    end
  end
end
