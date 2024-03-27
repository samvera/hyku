# frozen_string_literal: true

RSpec.describe Hyrax::SolrDocumentBehavior, type: :decorator do
  subject(:solr_document) { solr_document_class.new(solr_hash) }
  let(:solr_hash) { {} }

  let(:solr_document_class) do
    Class.new do
      include Blacklight::Solr::Document
      include Hyrax::SolrDocumentBehavior
    end
  end

  describe '#to_partial_path' do
    context 'with an ActiveFedora model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork' } }

      it 'resolves the correct model name' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/generic_works/generic_work'
      end
    end

    context 'with a Valkyrie model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWorkResource' } }

      # Yes, a GenericWorkResource will resolves to the `hyrax/generic_works/generic_work` because
      # we're migrating from GenericWork.
      it 'resolves the correct model name' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/generic_works/generic_work'
      end
    end

    context 'with a Valkyrie migration model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork', 'valkyrie_bsi' => true } }

      it 'resolves the correct model name' do
        expect(solr_document.to_model.to_partial_path).to eq 'hyrax/generic_works/generic_work'
      end
    end
  end

  describe '#hydra_model' do
    it 'gives ActiveFedora::Base by default' do
      expect(solr_document.hydra_model).to eq ActiveFedora::Base
    end

    context 'with an ActiveFedora model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork' } }

      it 'resolves the correct model name' do
        expect(solr_document.hydra_model).to eq GenericWork
      end
    end

    context 'with a Valkyrie model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWorkResource' } }

      it 'resolves the correct model name' do
        expect(solr_document.hydra_model).to eq GenericWorkResource
      end
    end

    context 'with a Valkyrie migration model name' do
      let(:solr_hash) { { 'has_model_ssim' => 'GenericWork', 'valkyrie_bsi' => true } }

      it 'resolves the correct model name' do
        expect(solr_document.hydra_model).to eq GenericWorkResource
      end
    end
  end
end
