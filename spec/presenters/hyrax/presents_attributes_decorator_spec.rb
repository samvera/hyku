# frozen_string_literal: true

RSpec.describe Hyrax::PresentsAttributesDecorator do
  subject(:presenter) { Hyrax::CollectionPresenter.new(SolrDocument.new(fields), Ability.new(nil)) }

  describe '#value_label_pairs' do
    context 'when the document carries indexed labels' do
      let(:fields) do
        { 'id' => 'c1', 'has_model_ssim' => ['Collection'], 'resource_type_tesim' => ['local_auth_123', 'Article'],
          'resource_type_label_tesim' => ['Opaque Term', 'Article'] }
      end

      it 'pairs each stored value with its label, including a label that is its id' do
        expect(presenter.value_label_pairs(:resource_type)).to eq [['local_auth_123', 'Opaque Term'], ['Article', 'Article']]
      end
    end

    context 'when the document carries no labels' do
      let(:fields) { { 'id' => 'c1', 'has_model_ssim' => ['Collection'], 'resource_type_tesim' => ['local_auth_123'] } }

      it 'pairs each stored value with nil' do
        expect(presenter.value_label_pairs(:resource_type)).to eq [['local_auth_123', nil]]
      end
    end
  end
end
