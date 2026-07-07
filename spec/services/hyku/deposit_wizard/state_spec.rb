# frozen_string_literal: true

RSpec.describe Hyku::DepositWizard::State do
  subject(:state) { described_class.new(store) }

  let(:store) { {} }

  it 'tolerates a nil store' do
    expect(described_class.new(nil).to_h).to eq({})
  end

  describe '#path' do
    it 'accepts a valid path' do
      state.path = 'standalone'
      expect(state.path).to eq('standalone')
    end

    it 'ignores an invalid path' do
      state.path = 'bogus'
      expect(state.path).to be_nil
    end
  end

  describe '#work_type' do
    it 'stores a present value' do
      state.work_type = 'GenericWorkResource'
      expect(state.work_type).to eq('GenericWorkResource')
    end

    it 'stores nil for a blank value' do
      state.work_type = ''
      expect(state.work_type).to be_nil
    end
  end

  it 'exposes the backing hash for the session' do
    state.path = 'new'
    state.work_type = 'GenericWorkResource'

    expect(state.to_h).to eq('path' => 'new', 'work_type' => 'GenericWorkResource')
  end
end
