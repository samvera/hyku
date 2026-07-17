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

  describe '#parent_id' do
    it 'stores a present value' do
      state.parent_id = 'abc-123'
      expect(state.parent_id).to eq('abc-123')
    end

    it 'stores nil for a blank value' do
      state.parent_id = ''
      expect(state.parent_id).to be_nil
    end
  end

  describe '#uploaded_file_ids' do
    it 'defaults to an empty array' do
      expect(state.uploaded_file_ids).to eq([])
    end

    it 'normalizes to unique, blank-free strings' do
      state.uploaded_file_ids = [1, '2', '2', '', nil]
      expect(state.uploaded_file_ids).to eq(%w[1 2])
    end
  end

  describe '#primary_file_id' do
    before { state.uploaded_file_ids = %w[10 20 30] }

    it 'falls back to the first uploaded file when unset' do
      expect(state.primary_file_id).to eq('10')
    end

    it 'returns the chosen id when it is among the uploaded files' do
      state.primary_file_id = '20'
      expect(state.primary_file_id).to eq('20')
    end

    it 'falls back to the first file when the chosen id is no longer present' do
      state.primary_file_id = '99'
      expect(state.primary_file_id).to eq('10')
    end
  end

  it 'exposes the backing hash for the session' do
    state.path = 'new'
    state.work_type = 'GenericWorkResource'

    expect(state.to_h).to eq('path' => 'new', 'work_type' => 'GenericWorkResource')
  end
end
