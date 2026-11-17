# frozen_string_literal: true

# TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax, with the overrides these examples cover
RSpec.describe 'collection page metadata', type: :view do
  let(:document) do
    SolrDocument.new('id' => 'c1', 'has_model_ssim' => ['CollectionResource'], 'schema_version_ssi' => '1',
                     'title_tesim' => ['Harbor Records'], 'abstract_tesim' => ['Maps of the harbor.'],
                     'call_number_tesim' => ['MS.0951'])
  end
  let(:presenter) { Hyrax::CollectionPresenter.new(document, Ability.new(nil)) }
  let(:page) { Capybara.string(rendered) }

  before do
    on_collections = { 'class' => ['CollectionResource'] }
    allow(Hyrax::FlexibleSchema).to receive_messages(
      current_version: { 'properties' => {
        'abstract' => { 'available_on' => on_collections, 'indexing' => ['abstract_tesim'], 'data_type' => 'array',
                        'display_label' => { 'default' => 'Summary' }, 'view' => { 'html_dl' => true } },
        'call_number' => { 'available_on' => on_collections, 'indexing' => ['call_number_tesim'], 'data_type' => 'array', 'view' => { 'html_dl' => true } }
      } },
      current_schema_id: 1
    )
    without_partial_double_verification { allow(view).to receive(:current_user).and_return(nil) }
    allow(Hyrax.config).to receive(:collection_terms).and_return(%i[call_number title abstract])
    assign(:presenter, presenter)
  end

  after do
    Hyku::CollectionProfileReaders.readers.each do |reader|
      Hyrax::CollectionPresenter.send(:remove_method, reader) if Hyrax::CollectionPresenter.method_defined?(reader, false)
    end
    Hyku::CollectionProfileReaders.readers.clear
  end

  %w[hyrax/collections/show_descriptions hyrax/dashboard/collections/show_descriptions].each do |partial|
    it "shows an app's listed fields the profile has, in its order, with the profile's labels, on #{partial}" do
      render partial: partial

      expect(page.all('dt').map { |term| term.text.strip }).to eq ['Call number', 'Summary']
      expect(page).to have_css('dd', text: 'MS.0951')
    end
  end
end
