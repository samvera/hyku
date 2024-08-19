# frozen_string_literal: true

RSpec.describe Hyrax::Actors::Environment, type: :decorator do
  let(:curation_concern) { double('curation_concern') }
  let(:current_ability) { double('current_ability') }
  let(:attributes) { {} }

  describe '#initialize' do
    context 'when importing is not explicitly set' do
      subject { described_class.new(curation_concern, current_ability, attributes) }

      it 'initializes with an importing flag set to false (default behavior)' do
        expect(subject.importing).to eq(false)
      end
    end

    context 'when importing is explicitly set' do
      let(:importing) { true }
      subject { described_class.new(curation_concern, current_ability, attributes, importing) }

      it 'initializes with an importing flag set to true' do
        expect(subject.importing).to eq(true)
      end
    end
  end
end
