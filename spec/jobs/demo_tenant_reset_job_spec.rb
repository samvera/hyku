# frozen_string_literal: true

RSpec.describe DemoTenantResetJob do
  let(:account) { create(:account, :public_schema, :public_demo_tenant) }
  let(:service) { instance_double(DemoTenantResetService, reset!: true) }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(DemoTenantResetService).to receive(:new).and_return(service)
  end

  after do
    clear_enqueued_jobs
  end

  describe '#perform' do
    it 'runs the reset service for the current tenant account' do
      switch!(account)
      described_class.perform_now
      expect(DemoTenantResetService).to have_received(:new)
        .with(hash_including(account:))
      expect(service).to have_received(:reset!)
    end

    it 'reschedules itself for tomorrow midnight' do
      switch!(account)
      expect { described_class.perform_now }
        .to have_enqueued_job(described_class).at(Date.tomorrow.midnight)
    end

    context 'when the account is not a public demo tenant' do
      let(:account) { create(:account, :public_schema) }

      it 'does not run the service and ends the nightly chain' do
        switch!(account)
        expect { described_class.perform_now }
          .not_to have_enqueued_job(described_class)
        expect(service).not_to have_received(:reset!)
      end
    end

    context 'when the reset fails' do
      before do
        allow(service).to receive(:reset!)
          .and_raise(DemoTenantResetService::HealthCheckFailed, 'validation red')
      end

      it 'does not chain a run for tomorrow (the daily maintenance pass re-seeds it)' do
        switch!(account)
        expect { described_class.perform_now }
          .not_to have_enqueued_job(described_class).at(Date.tomorrow.midnight)
      end
    end

    describe 'seed path templating' do
      around do |example|
        original = ENV.fetch('DEMO_SEED_CSV_PATH', nil)
        ENV['DEMO_SEED_CSV_PATH'] = '/imports/%{tenant}/metadata.csv'
        example.run
        original ? ENV['DEMO_SEED_CSV_PATH'] = original : ENV.delete('DEMO_SEED_CSV_PATH')
      end

      it 'expands the tenant name into DEMO_SEED_CSV_PATH' do
        switch!(account)
        described_class.perform_now
        expect(DemoTenantResetService).to have_received(:new)
          .with(hash_including(seed_csv_path: "/imports/#{account.name}/metadata.csv"))
      end
    end
  end
end
