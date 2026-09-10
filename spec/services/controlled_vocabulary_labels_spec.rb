# frozen_string_literal: true

RSpec.describe ControlledVocabularyLabels do
  let(:profile) do
    {
      'properties' => {
        'rights_statement' => {
          'controlled_values' => { 'sources' => ['rights_statements'] },
          'indexing' => ['rights_statement_sim', 'rights_statement_tesim']
        },
        'subject' => {
          'controlled_values' => { 'sources' => ['  plan_test_vocab  '] },
          'indexing' => ['subject_tesim']
        },
        'remote_field' => {
          'controlled_values' => { 'sources' => ['loc/subjects'] },
          'indexing' => ['remote_field_tesim']
        },
        'title' => {
          'controlled_values' => { 'sources' => ['null'] },
          'indexing' => ['title_tesim']
        }
      }
    }
  end

  let(:vocabulary) do
    Qa::LocalAuthority.find_or_create_by!(name: 'plan_test_vocab') { |a| a.label = 'Plan Test Vocab' }
  end

  before do
    described_class.reset!
    vocabulary
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(instance_double(Hyrax::FlexibleSchema, profile:))
  end

  after { described_class.reset! }

  describe '.source_for' do
    it 'returns the authority a controlled property cites' do
      expect(described_class.source_for(:rights_statement)).to eq 'rights_statements'
    end

    it 'strips whitespace profiles have shipped around a source' do
      expect(described_class.source_for(:subject)).to eq 'plan_test_vocab'
    end

    it 'is nil for a property whose only source is the null sentinel' do
      expect(described_class.source_for(:title)).to be_nil
    end

    it 'is nil for a property the profile does not declare' do
      expect(described_class.source_for(:not_a_property)).to be_nil
    end

    describe 'a malformed or empty declaration' do
      {
        'no controlled_values at all' => { 'indexing' => ['x_tesim'] },
        'controlled_values nil' => { 'controlled_values' => nil },
        'controlled_values not a hash' => { 'controlled_values' => 'licenses' },
        'sources missing' => { 'controlled_values' => { 'format' => 'string' } },
        'sources nil' => { 'controlled_values' => { 'sources' => nil } },
        'sources empty' => { 'controlled_values' => { 'sources' => [] } },
        'sources all nil' => { 'controlled_values' => { 'sources' => [nil] } },
        'sources all blank' => { 'controlled_values' => { 'sources' => ['', '   '] } },
        'sources only the null sentinel' => { 'controlled_values' => { 'sources' => ['null'] } },
        'sources only NULL uppercase' => { 'controlled_values' => { 'sources' => ['NULL'] } },
        'sources name no existing vocabulary' => { 'controlled_values' => { 'sources' => ['typo_vocab'] } }
      }.each do |description, config|
        it "is nil when #{description}" do
          profile['properties']['edge_case'] = config

          expect(described_class.source_for(:edge_case)).to be_nil
        end
      end

      it 'is not a hash itself' do
        profile['properties']['edge_case'] = 'not a config'

        expect(described_class.source_for(:edge_case)).to be_nil
      end

      it 'takes the first source naming a vocabulary that exists' do
        profile['properties']['edge_case'] =
          { 'controlled_values' => { 'sources' => ['null', 'typo_vocab', '  licenses  '] } }

        expect(described_class.source_for(:edge_case)).to eq 'licenses'
      end

      it 'keeps a remote authority, which the deposit form still needs' do
        profile['properties']['edge_case'] =
          { 'controlled_values' => { 'sources' => ['loc/subjects'] } }

        expect(described_class.source_for(:edge_case)).to eq 'loc/subjects'
      end
    end

    context 'when flexible metadata is off' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it 'reads the static mapping instead of a profile' do
        expect(described_class.source_for(:license)).to eq 'licenses'
      end

      it 'is nil for an unmapped property' do
        expect(described_class.source_for(:title)).to be_nil
      end
    end
  end

  describe '.source_for with a schema_version' do
    let(:old_profile) do
      { 'properties' => { 'subject' => { 'controlled_values' => { 'sources' => [source] } } } }
    end

    before do
      allow(Hyrax::FlexibleSchema).to receive(:find_by).with(id: 41)
                                                       .and_return(instance_double(Hyrax::FlexibleSchema, profile: old_profile))
    end

    context 'when that profile cites a vocabulary that still exists' do
      let(:source) { 'licenses' }

      it 'resolves against that profile rather than the newest' do
        expect(described_class.source_for(:subject, schema_version: 41)).to eq 'licenses'
      end
    end

    context 'when that profile cites a vocabulary since removed' do
      let(:source) { 'retired_vocab' }

      it 'is nil, the same answer as an uncontrolled property' do
        expect(described_class.source_for(:subject, schema_version: 41)).to be_nil
      end
    end
  end

  describe '.sources_for' do
    let(:configs) do
      profile['properties'].transform_keys(&:to_sym).transform_values { |c| c }
    end

    before do
      allow(Hyrax::Schema).to receive(:m3_schema_loader).and_return(
        instance_double(Hyrax::M3SchemaLoader, raw_attribute_configs: configs)
      )
    end

    it 'maps every controlled property to its authority in one pass' do
      expect(described_class.sources_for(model: 'GenericWorkResource')).to eq(
        'rights_statement' => 'rights_statements',
        'subject' => 'plan_test_vocab',
        'remote_field' => 'loc/subjects'
      )
    end

    it 'omits properties that are free text' do
      expect(described_class.sources_for(model: 'GenericWorkResource')).not_to have_key('title')
    end

    it 'is empty without a model, since two entries can share an attribute name' do
      expect(described_class.sources_for).to eq({})
    end

    context 'when flexible metadata is off' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it 'returns the static mapping without needing a model' do
        expect(described_class.sources_for).to include('license' => 'licenses')
      end
    end

    describe 'a property two profile entries describe, one naming the other with name:' do
      let(:schema) { Hyrax::FlexibleSchema.create(profile: shipped_profile) }
      let(:shipped_profile) { YAML.load_file(Rails.root.join('config', 'metadata_profiles', 'm3_profile.yaml')) }

      # Undoes the stubs above so these read the real loader: collapsing `name:`
      # and applying `available_on` is the behavior under test, and a doubled
      # loader would pass while exercising none of it.
      before do
        allow(Hyrax::FlexibleSchema).to receive(:find_by).and_call_original
        allow(Hyrax::Schema).to receive(:m3_schema_loader).and_call_original
      end

      after { schema.destroy }

      it 'gives an OER work the authority its own entry cites' do
        sources = described_class.sources_for(schema_version: schema.id, model: 'OerResource')

        expect(sources['resource_type']).to eq 'oer_types'
      end

      it 'gives every other work type the general authority' do
        sources = described_class.sources_for(schema_version: schema.id, model: 'GenericWorkResource')

        expect(sources['resource_type']).to eq 'resource_types'
      end

      it 'does not emit the surrogate name, which no resource has an attribute for' do
        sources = described_class.sources_for(schema_version: schema.id, model: 'OerResource')

        expect(sources).not_to have_key('oer_resource_type')
      end
    end
  end

  describe '.labels_for' do
    before do
      vocabulary.local_authority_entries.find_or_create_by!(uri: 'local_auth_123') do |entry|
        entry.label = 'Opaque Term'
        entry.active = true
      end
    end

    it 'resolves a stored id to its label' do
      expect(described_class.labels_for('plan_test_vocab', ['local_auth_123'])).to eq ['Opaque Term']
    end

    it 'keeps a value the authority does not know' do
      expect(described_class.labels_for('plan_test_vocab', ['not_a_term'])).to eq ['not_a_term']
    end

    it 'keeps an unresolved value in place so the array stays index-aligned' do
      values = ['not_a_term', 'local_auth_123', 'also_unknown']

      expect(described_class.labels_for('plan_test_vocab', values))
        .to eq ['not_a_term', 'Opaque Term', 'also_unknown']
    end

    it 'accepts a single value' do
      expect(described_class.labels_for('plan_test_vocab', 'local_auth_123')).to eq ['Opaque Term']
    end

    it 'returns the values unchanged when no source is given' do
      expect(described_class.labels_for(nil, ['local_auth_123'])).to eq ['local_auth_123']
    end

    it 'resolves a URI-valued id, the shape licenses and rights statements use' do
      expect(described_class.labels_for('licenses', ['http://creativecommons.org/licenses/by/3.0/us/']))
        .to eq ['Attribution 3.0 United States']
    end

    it 'returns the values unchanged for an authority that does not exist' do
      expect(described_class.labels_for('no_such_vocabulary', ['local_auth_123'])).to eq ['local_auth_123']
    end

    it 'returns the values unchanged for a blank source' do
      expect(described_class.labels_for('   ', ['local_auth_123'])).to eq ['local_auth_123']
    end

    it 'is empty for no values' do
      expect(described_class.labels_for('plan_test_vocab', nil)).to eq []
    end

    it 'keeps a blank value in its slot rather than dropping it' do
      expect(described_class.labels_for('plan_test_vocab', ['', 'local_auth_123']))
        .to eq ['', 'Opaque Term']
    end
  end

  describe '.resolvable?' do
    it 'is true for a vocabulary this tenant has rows for' do
      vocabulary
      expect(described_class.resolvable?('plan_test_vocab')).to be true
    end

    it 'is false for a remote authority, which would need a request per value' do
      expect(described_class.resolvable?('loc/subjects')).to be false
    end

    it 'is false for a blank source' do
      expect(described_class.resolvable?(nil)).to be false
    end
  end

  describe 'authority backends' do
    it 'resolves a yaml-backed authority with no database rows' do
      expect(described_class.labels_for('licenses', ['http://creativecommons.org/licenses/by/3.0/us/']))
        .to eq ['Attribution 3.0 United States']
    end
  end
end
