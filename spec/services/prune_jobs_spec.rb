# frozen_string_literal: true

RSpec.describe PruneJobs do
  before { allow(ENV).to receive(:fetch).and_call_original }

  describe '.options_from_env' do
    it 'uses the given age and the defaults' do
      expect(described_class.options_from_env(older_than_days: 30))
        .to eq(older_than_days: 30, batch_size: 5_000, batch_sleep_seconds: 1.0, dry_run: false)
    end

    it 'reads the environment' do
      allow(ENV).to receive(:fetch).with('OLDER_THAN_DAYS', anything).and_return('3')
      allow(ENV).to receive(:fetch).with('BATCH_SIZE', anything).and_return('10')
      allow(ENV).to receive(:fetch).with('BATCH_SLEEP_SECONDS', anything).and_return('0')
      allow(ENV).to receive(:fetch).with('DRY_RUN', anything).and_return('true')

      expect(described_class.options_from_env(older_than_days: 30))
        .to eq(older_than_days: 3, batch_size: 10, batch_sleep_seconds: 0.0, dry_run: true)
    end

    it 'raises on a non-integer OLDER_THAN_DAYS' do
      allow(ENV).to receive(:fetch).with('OLDER_THAN_DAYS', anything).and_return('')

      expect { described_class.options_from_env(older_than_days: 30) }.to raise_error(ArgumentError)
    end

    it 'raises on a zero or negative OLDER_THAN_DAYS' do
      allow(ENV).to receive(:fetch).with('OLDER_THAN_DAYS', anything).and_return('0')

      expect { described_class.options_from_env(older_than_days: 30) }
        .to raise_error(ArgumentError, 'OLDER_THAN_DAYS must be at least 1')
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
