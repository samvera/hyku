# frozen_string_literal: true

RSpec.describe DemoTenantResetJob do
  include ActiveSupport::Testing::TimeHelpers

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

      # Expanding %{tenant} moved into DemoTenantResetService so hyku:demo:reset
      # gets it too, and is asserted there. This only checks the handover.
      it 'passes DEMO_SEED_CSV_PATH through for the service to resolve' do
        switch!(account)
        described_class.perform_now
        expect(DemoTenantResetService).to have_received(:new)
          .with(hash_including(seed_csv_path: '/imports/%{tenant}/metadata.csv'))
      end
    end
  end

  describe '.next_run_at' do
    around do |example|
      original = ENV.fetch('DEMO_RESET_TIME', nil)
      reset_time ? ENV['DEMO_RESET_TIME'] = reset_time : ENV.delete('DEMO_RESET_TIME')
      example.run
      original ? ENV['DEMO_RESET_TIME'] = original : ENV.delete('DEMO_RESET_TIME')
    end

    let(:pacific) { ActiveSupport::TimeZone['America/Los_Angeles'] }

    context 'when DEMO_RESET_TIME is unset' do
      let(:reset_time) { nil }

      it 'is tomorrow midnight' do
        expect(described_class.next_run_at).to eq(Date.tomorrow.midnight)
      end
    end

    context 'with a time and zone' do
      let(:reset_time) { '03:00 America/Los_Angeles' }

      context 'when the time has not passed yet' do
        it 'is later today' do
          now = pacific.local(2026, 11, 2, 1, 0)
          expect(described_class.next_run_at(now)).to eq(pacific.local(2026, 11, 2, 3, 0))
        end
      end

      context 'when the local date differs from the UTC date' do
        let(:reset_time) { '21:00 America/Los_Angeles' }

        it 'uses the local date' do
          expect(described_class.next_run_at(Time.utc(2026, 11, 3, 4, 0))).to eq(pacific.local(2026, 11, 2, 21, 0))
        end
      end

      it 'stays at 03:00 local across the fall-back DST change' do
        now = pacific.local(2026, 10, 31, 3, 20)
        run_at = described_class.next_run_at(now)
        expect(run_at).to eq(pacific.local(2026, 11, 1, 3, 0))
        expect(run_at.utc).to eq(Time.utc(2026, 11, 1, 11, 0))
      end

      it 'stays at 03:00 local across the spring-forward DST change' do
        now = pacific.local(2027, 3, 13, 3, 20)
        run_at = described_class.next_run_at(now)
        expect(run_at).to eq(pacific.local(2027, 3, 14, 3, 0))
        expect(run_at.utc).to eq(Time.utc(2027, 3, 14, 10, 0))
      end
    end

    context 'with a time and no zone' do
      let(:reset_time) { '09:30' }

      it 'uses the application time zone' do
        now = Time.zone.local(2026, 11, 2, 12, 0)
        expect(described_class.next_run_at(now)).to eq(Time.zone.local(2026, 11, 3, 9, 30))
      end
    end

    ['25:00', '3am', '03:00 Mars/Olympus_Mons'].each do |invalid|
      context "with an invalid value #{invalid.inspect}" do
        let(:reset_time) { invalid }

        it 'falls back to tomorrow midnight and logs a warning' do
          allow(Rails.logger).to receive(:warn)
          expect(described_class.next_run_at).to eq(Date.tomorrow.midnight)
          expect(Rails.logger).to have_received(:warn).with(/invalid DEMO_RESET_TIME/)
        end
      end
    end

    describe 'scheduling' do
      let(:reset_time) { '03:00 America/Los_Angeles' }
      let(:now) { pacific.local(2026, 11, 2, 4, 0) }

      around { |example| travel_to(now) { example.run } }

      it 'reschedules each reset for the configured time' do
        switch!(account)
        expect { described_class.perform_now }
          .to have_enqueued_job(described_class).at(pacific.local(2026, 11, 3, 3, 0))
      end

      it 'schedules the first run for the configured time' do
        expect { described_class.schedule_first_run }
          .to have_enqueued_job(described_class).at(pacific.local(2026, 11, 3, 3, 0))
      end

      context 'when DEMO_RESET_TIME is invalid' do
        let(:reset_time) { '25:00' }

        it 'waits for the midnight fallback instead of running right away' do
          expect { described_class.schedule_first_run }
            .to have_enqueued_job(described_class).at(Date.tomorrow.midnight)
        end
      end

      context 'when DEMO_RESET_TIME is unset' do
        let(:reset_time) { nil }

        it 'runs the first reset right away' do
          expect { described_class.schedule_first_run }
            .to have_enqueued_job(described_class).at(:no_wait)
        end
      end
    end
  end
end
