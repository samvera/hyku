# frozen_string_literal: true

RSpec.describe Hyrax::FormHelperBehavior, type: :helper do
  describe '#controlled_vocabulary_source_for' do
    context 'when flexible=false' do
      before do
        allow(Hyrax.config).to receive(:flexible?).and_return(false)
      end

      it 'returns controlled vocabulary service keys' do
        expect(helper.send(:controlled_vocabulary_source_for, :audience)).to eq('audience')
        expect(helper.send(:controlled_vocabulary_source_for, :discipline)).to eq('discipline')
        expect(helper.send(:controlled_vocabulary_source_for, :education_level)).to eq('education_levels')
        expect(helper.send(:controlled_vocabulary_source_for, 'learning_resource_type')).to eq('learning_resource_types')
        expect(helper.send(:controlled_vocabulary_source_for, :license)).to eq('licenses')
        expect(helper.send(:controlled_vocabulary_source_for, :resource_type)).to eq('resource_types')
        expect(helper.send(:controlled_vocabulary_source_for, :rights_statement)).to eq('rights_statements')
      end
    end
  end
end
