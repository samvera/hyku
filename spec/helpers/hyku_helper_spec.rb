# frozen_string_literal: true

RSpec.describe HykuHelper, type: :helper do
  describe 'parent_path' do
    let(:parent_doc) { SolrDocument.new(id: '123', has_model_ssim: ['GenericWork']) }

    it 'returns the path to the parent' do
      expect(helper.parent_path(parent_doc)).to eq("/concern/generic_works/#{parent_doc.id}")
    end
  end
end
