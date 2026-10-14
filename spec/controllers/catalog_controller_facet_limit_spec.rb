# frozen_string_literal: true

RSpec.describe 'catalog facet limits' do
  let(:catalog) do
    Class.new(CatalogController) do
      include Hyrax::FlexibleCatalogBehavior
      def self.name
        'FacetLimitProbeController'
      end
    end
  end

  let(:profile) { YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')) }
  let(:search_builder) { catalog.blacklight_config.search_builder_class.new(catalog.new) }

  before do
    profile['properties']['profile_only_field'] = {
      'available_on' => { 'class' => ['GenericWorkResource'] },
      'display_label' => { 'default' => 'Profile Only Field' },
      'indexing' => %w[profile_only_field_tesim profile_only_field_sim stored_searchable facetable],
      'data_type' => 'array',
      'range' => 'http://www.w3.org/2001/XMLSchema#string'
    }
    @schema = Hyrax::FlexibleSchema.create(profile:)
    catalog.load_flexible_schema
  end

  after { @schema&.destroy }

  it 'lists as many values for a facet only the profile adds as for a declared facet' do
    expect(search_builder.facet_limit_for('profile_only_field_sim'))
      .to eq(search_builder.facet_limit_for('keyword_sim'))
      .and eq 5
  end
end
