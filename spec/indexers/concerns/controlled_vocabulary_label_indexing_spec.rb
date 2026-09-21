# frozen_string_literal: true

RSpec.describe 'controlled vocabulary label indexing' do
  let(:vocabulary) do
    Qa::LocalAuthority.find_or_create_by!(name: 'plan_test_vocab') { |a| a.label = 'Plan Test Vocab' }
  end

  let(:attributes) { {} }
  let(:resource) { FactoryBot.valkyrie_create(:generic_work_resource, title: ['Label Indexing Work'], **attributes) }
  let(:solr_doc) { Hyrax::Indexers::ResourceIndexer.for(resource:).to_solr }
  let(:label_service) { Hyrax.config.controlled_vocabulary_label_service }

  before do
    vocabulary.local_authority_entries.find_or_create_by!(uri: 'local_auth_123') do |entry|
      entry.label = 'Opaque Term'
      entry.active = true
    end
    # After the rows exist, not before: the service memoizes which vocabularies
    # it found, and a miss cached by an earlier example outlives the wipe.
    label_service.reset!
  end

  after { label_service.reset! }

  context 'for a resource whose profile controls resource_type' do
    # Stubbed on the indexer module rather than the loader: the module memoizes
    # the authorities it resolved per schema, so any earlier example that
    # indexed a work has already cached an answer a loader stub cannot displace.
    before do
      allow_any_instance_of(Hyrax::Indexer)
        .to receive(:authorities_for).and_return(resource_type: 'plan_test_vocab')
    end

    context 'when a term id differs from its label' do
      let(:attributes) { { resource_type: ['local_auth_123'] } }

      it 'indexes the label into the label field' do
        expect(solr_doc['resource_type_label_tesim']).to eq ['Opaque Term']
      end

      it 'leaves the stored id in the original field' do
        expect(solr_doc['resource_type_tesim']).to eq ['local_auth_123']
      end
    end

    context 'with several values where only some resolve' do
      let(:attributes) { { resource_type: ['not_a_term', 'local_auth_123'] } }

      it 'keeps an unresolved value in place so the arrays stay index-aligned' do
        expect(solr_doc['resource_type_label_tesim']).to eq ['not_a_term', 'Opaque Term']
      end
    end

    context 'for a property that is not controlled' do
      it 'adds no label field' do
        expect(solr_doc).not_to have_key('title_label_tesim')
      end

      it 'indexes its value unchanged' do
        expect(solr_doc['title_tesim']).to eq ['Label Indexing Work']
      end
    end

    context 'when no property is controlled' do
      before do
        allow_any_instance_of(Hyrax::Indexer).to receive(:authorities_for).and_return({})
      end

      it 'adds none of its own, leaving Hyrax LocationIndexer based_near_label alone' do
        expect(solr_doc.keys.grep(/_label_/)).to eq %w[based_near_label_sim based_near_label_tesim]
      end
    end
  end

  # The yaml schemas carry their own controlled_values, so a non-flexible tenant
  # resolves authorities without a profile. Read from the schema rather than a
  # loader instance, which another spec may have stubbed.
  it 'takes the authority its yaml schema declares' do
    config = YAML.safe_load_file(Rails.root.join('config', 'metadata', 'basic_metadata.yaml'))

    expect(config.dig('attributes', 'resource_type', 'controlled_values', 'sources'))
      .to eq ['resource_types']
  end

  it 'gives an OER work the authority its own schema declares, not the general one' do
    config = YAML.safe_load_file(Rails.root.join('config', 'metadata', 'oer_resource.yaml'))

    expect(config.dig('attributes', 'resource_type', 'controlled_values', 'sources'))
      .to eq ['oer_types']
  end
end
