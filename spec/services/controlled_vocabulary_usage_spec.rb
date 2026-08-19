# frozen_string_literal: true

RSpec.describe ControlledVocabularyUsage do
  let(:profile) do
    {
      'classes' => {
        'GenericWorkResource' => { 'display_label' => 'Generic Work' },
        'ImageResource' => { 'display_label' => 'Image' },
        'Hyrax::FileSet' => { 'display_label' => 'File Set' }
      },
      'properties' => {
        'license' => {
          'available_on' => { 'class' => ['GenericWorkResource', 'ImageResource', 'Hyrax::FileSet'] },
          'controlled_values' => { 'sources' => ['licenses'] },
          'display_label' => { 'default' => 'blacklight.search.fields.index.license_tesim' }
        },
        'rights_statement' => {
          'available_on' => { 'class' => ['GenericWorkResource'] },
          # A second source on the same property, and whitespace a shipped
          # profile has been seen to carry.
          'controlled_values' => { 'sources' => [' licenses', 'rights_statements'] },
          'display_label' => { 'default' => 'Rights Statement' }
        },
        'creator' => {
          'available_on' => { 'class' => ['GenericWorkResource'] },
          'controlled_values' => { 'sources' => ['null'] }
        }
      }
    }
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(profile)
  end

  describe '.citing' do
    it 'returns every property citing the vocabulary' do
      expect(described_class.citing('licenses').map(&:name)).to eq %w[license rights_statement]
    end

    it 'reads the profile once' do
      described_class.citing('licenses')

      expect(Hyrax::FlexibleSchema).to have_received(:current_version).once
    end

    it 'labels each work type from the profile classes section, keeping the class name' do
      work_types = described_class.citing('licenses').first.work_types

      expect(work_types.map(&:label)).to eq ['Generic Work', 'Image', 'File Set']
      expect(work_types.map(&:name)).to eq ['GenericWorkResource', 'ImageResource', 'Hyrax::FileSet']
    end

    it 'keeps the work type list per property' do
      rights = described_class.citing('licenses').last

      expect(rights.work_types.map(&:name)).to eq ['GenericWorkResource']
    end

    it 'finds a property through a second source' do
      expect(described_class.citing('rights_statements').map(&:name)).to eq ['rights_statement']
    end

    it 'returns an empty array when no property cites the vocabulary' do
      expect(described_class.citing('subjects')).to eq []
    end

    it 'labels a work type by its class name when the profile does not name it' do
      profile['classes'].delete('ImageResource')

      labels = described_class.citing('licenses').first.work_types.map(&:label)

      expect(labels).to eq ['Generic Work', 'ImageResource', 'File Set']
    end

    # Profiles shipped before the fix label CollectionResource "pcdmcollection".
    it 'corrects a work type label the shipped profile got wrong' do
      profile['classes']['CollectionResource'] = { 'display_label' => 'pcdmcollection' }
      profile['properties']['license']['available_on']['class'] << 'CollectionResource'

      labels = described_class.citing('licenses').first.work_types.map(&:label)

      expect(labels).to include 'Collection'
      expect(labels).not_to include 'pcdmcollection'
    end

    it 'keeps a label the tenant chose deliberately' do
      profile['classes']['CollectionResource'] = { 'display_label' => 'Series' }
      profile['properties']['license']['available_on']['class'] << 'CollectionResource'

      expect(described_class.citing('licenses').first.work_types.map(&:label)).to include 'Series'
    end

    it 'returns nil when the tenant has no profile yet' do
      allow(Hyrax::FlexibleSchema).to receive(:current_version).and_return(nil)

      expect(described_class.citing('licenses')).to be_nil
    end

    context 'when flexible metadata is off' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it 'answers from the form mapping instead of a profile' do
        properties = described_class.citing('licenses')

        expect(properties.map(&:name)).to eq ['license']
        expect(Hyrax::FlexibleSchema).not_to have_received(:current_version)
      end

      it 'lists the work types whose model defines the property' do
        names = described_class.citing('licenses').first.work_types.map(&:name)

        expect(names).to include 'GenericWorkResource'
        expect(names).not_to include 'GenericWork'
      end

      it 'labels the work types without the Valkyrie suffix' do
        labels = described_class.citing('licenses').first.work_types.map(&:label)

        expect(labels).to include 'Generic Work'
        expect(labels).to include 'ETD'
      end

      # The OER form reads resource_type from oer_types through its own partial,
      # not the generic mapping, so the vocabulary must not read as unused.
      it 'reports a vocabulary a form partial reads outside the mapping' do
        properties = described_class.citing('oer_types')

        expect(properties.map(&:name)).to eq ['resource_type']
        expect(properties.first.work_types.map(&:name)).to eq ['OerResource']
      end

      it 'returns an empty array for a vocabulary the mapping does not cite' do
        expect(described_class.citing('reading_rooms')).to eq []
      end
    end
  end
end
