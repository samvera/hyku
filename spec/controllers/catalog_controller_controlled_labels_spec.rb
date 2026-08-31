# frozen_string_literal: true

# Exercised against the real Hyrax::FlexibleCatalogBehavior rather than a
# hand-built field config, since what the catalog does with a controlled property
# is decided by the profile at load time.
RSpec.describe 'catalog rendering of controlled vocabulary labels' do
  let(:catalog) do
    Class.new(CatalogController) do
      include Hyrax::FlexibleCatalogBehavior
      def self.name
        'ControlledLabelsProbeController'
      end
    end
  end

  let(:profile) { YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')) }

  def load_profile!
    @schema = Hyrax::FlexibleSchema.create(profile:)
    catalog.load_flexible_schema
  end

  def rendered(property, values: ['id_1'], label: 'Readable Term')
    config = catalog.blacklight_config.index_fields["#{property}_tesim"]
    return if config.nil?

    document = SolrDocument.new("#{property}_tesim" => values,
                                "#{property}_label_tesim" => [label])
    Blacklight::FieldRetriever.new(document, config, nil).fetch
  end

  after { @schema&.destroy }

  describe 'a property declared in CatalogController' do
    context 'when the profile leaves it un-facetable' do
      it 'shows the term label' do
        load_profile!

        expect(rendered('education_level')).to eq ['Readable Term']
      end
    end

    # Blacklight queries a facet with whatever value the row rendered, so a row
    # showing labels only links anywhere if the facet holds labels too.
    context 'when the profile marks it facetable' do
      before { profile['properties']['education_level']['indexing'] << 'facetable' }

      it 'facets on the label field' do
        load_profile!

        expect(catalog.blacklight_config.facet_fields.keys).to include 'education_level_label_sim'
      end

      it 'hides the id facet so staff are not offered the filter twice' do
        load_profile!

        expect(catalog.blacklight_config.facet_fields['education_level_sim'].show).to be false
      end

      # Bookmarks, saved searches and the theme views that build their own facet
      # links all carry the id key, and a dropped constraint fails silently: the
      # search returns everything rather than erroring.
      it 'still applies a filter built on the id facet' do
        load_profile!
        params = ActionController::Parameters.new(f: { 'education_level_sim' => ['id_1'] }).permit!
        state = Blacklight::SearchState.new(params, catalog.blacklight_config)

        expect(state.filters.map(&:key)).to include 'education_level_sim'
      end

      it 'keeps the id facet resolvable for facet_field_response' do
        load_profile!

        expect(catalog.blacklight_config.facet_fields).to have_key 'education_level_sim'
      end

      # keyword rather than the property above: it is declared in CatalogController
      # without a label, which is what leaves a titleized key to surface.
      it 'keeps the human label rather than the titleized solr key' do
        profile['properties']['keyword']['controlled_values'] = { 'sources' => ['licenses'] }
        profile['properties']['keyword']['indexing'] << 'facetable'
        load_profile!

        label = catalog.blacklight_config.facet_fields['keyword_label_sim']&.display_label('facet')

        expect(label).to eq 'Keyword'
      end

      it 'links the row at the label facet' do
        load_profile!

        expect(catalog.blacklight_config.index_fields['education_level_tesim'].link_to_facet)
          .to eq 'education_level_label_sim'
      end

      it 'still shows the term label' do
        load_profile!

        expect(rendered('education_level')).to eq ['Readable Term']
      end
    end

    it 'drops the facet upstream builds under a surrogate own key, which holds nothing' do
      load_profile!

      expect(catalog.blacklight_config.facet_fields).not_to have_key 'oer_resource_type_sim'
    end
  end

  it 'survives load_flexible_schema running again on every request' do
    load_profile!
    4.times { catalog.load_flexible_schema }
    facets = catalog.blacklight_config.facet_fields

    expect(facets.keys.grep(/resource_type/)).to eq %w[resource_type_sim resource_type_label_sim]
    expect(facets.select { |_, f| f.show != false }.keys.grep(/resource_type/))
      .to eq ['resource_type_label_sim']
  end

  # Stubbed rather than saved: Hyrax's validator rejects a scalar config, so only a
  # rake task writing the column directly can produce one.
  it 'ignores a property whose config is not a hash' do
    allow(catalog).to receive(:profile_properties)
      .and_return('good' => { 'controlled_values' => { 'sources' => ['licenses'] } },
                  'malformed' => 'not a config')

    expect { catalog.send(:apply_controlled_vocabulary_labels!) }.not_to raise_error
  end

  describe 'a property and vocabulary added only to the profile' do
    let(:vocabulary) do
      Qa::LocalAuthority.find_or_create_by!(name: 'brand_new_vocab') { |a| a.label = 'Brand New' }
    end

    before do
      vocabulary
      ControlledVocabularyLabels.reset!
      profile['properties']['brand_new_field'] = {
        'available_on' => { 'class' => ['GenericWorkResource'] },
        'controlled_values' => { 'sources' => ['brand_new_vocab'] },
        'display_label' => { 'default' => 'Brand New Field' },
        'indexing' => %w[brand_new_field_tesim brand_new_field_sim stored_searchable facetable],
        'data_type' => 'array',
        'range' => 'http://www.w3.org/2001/XMLSchema#string'
      }
    end

    after { ControlledVocabularyLabels.reset! }

    it 'shows the term label' do
      load_profile!

      expect(rendered('brand_new_field')).to eq ['Readable Term']
    end

    it 'facets on the label field' do
      load_profile!

      expect(catalog.blacklight_config.facet_fields.keys).to include 'brand_new_field_label_sim'
    end

    it 'links the row at the label facet' do
      load_profile!

      expect(catalog.blacklight_config.index_fields['brand_new_field_tesim'].link_to_facet)
        .to eq 'brand_new_field_label_sim'
    end
  end
end
