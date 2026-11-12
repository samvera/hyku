# frozen_string_literal: true

RSpec.describe PruneJobs do
  before { allow(ENV).to receive(:fetch).and_call_original }

  describe '.enabled?' do
    it 'is off by default' do
      expect(described_class).not_to be_enabled
    end

    it 'is on when HYKU_SCHEDULE_PRUNE_JOBS is true' do
      allow(ENV).to receive(:fetch).with('HYKU_SCHEDULE_PRUNE_JOBS', anything).and_return('true')

      expect(described_class).to be_enabled
    end
  end

  describe '.max_batches' do
    it 'defaults to 100' do
      expect(described_class.max_batches).to eq 100
    end

    it 'reads HYKU_PRUNE_MAX_BATCHES' do
      allow(ENV).to receive(:fetch).with('HYKU_PRUNE_MAX_BATCHES', anything).and_return('7')

      expect(described_class.max_batches).to eq 7
    end
  end
end
