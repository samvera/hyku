# frozen_string_literal: true

RSpec.describe 'controlled vocabulary label indexing' do
  let(:vocabulary) do
    Qa::LocalAuthority.find_or_create_by!(name: 'plan_test_vocab') { |a| a.label = 'Plan Test Vocab' }
  end

  let(:attributes) { {} }
  let(:resource) { FactoryBot.valkyrie_create(:generic_work_resource, title: ['Label Indexing Work'], **attributes) }
  let(:solr_doc) { Hyrax::Indexers::ResourceIndexer.for(resource:).to_solr }

  before do
    ControlledVocabularyLabels.reset!
    vocabulary.local_authority_entries.find_or_create_by!(uri: 'local_auth_123') do |entry|
      entry.label = 'Opaque Term'
      entry.active = true
    end
  end

  after { ControlledVocabularyLabels.reset! }

  context 'for a resource whose profile controls resource_type' do
    before do
      allow(ControlledVocabularyLabels).to receive(:sources_for)
        .and_return('resource_type' => 'plan_test_vocab')
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
      before { allow(ControlledVocabularyLabels).to receive(:sources_for).and_return({}) }

      it 'adds none of its own, leaving Hyrax LocationIndexer based_near_label alone' do
        expect(solr_doc.keys.grep(/_label_/)).to eq %w[based_near_label_sim based_near_label_tesim]
      end
    end
  end

  it 'takes the authority from the static mapping when flexible metadata is off' do
    expect(ControlledVocabularyLabels.sources_for).to include('resource_type' => 'resource_types')
  end

  it 'passes the resource own class, which is what tells two entries for one attribute apart' do
    expect(ControlledVocabularyLabels).to receive(:sources_for)
      .with(hash_including(model: resource.class))
      .at_least(:once).and_return({})

    solr_doc
  end
end
