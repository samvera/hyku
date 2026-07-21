# frozen_string_literal: true

RSpec.describe DemoTenantResetService do
  let(:account) { FactoryBot.create(:demo_account) }
  let(:snapshot) do
    {
      'site' => {},
      'content_blocks' => {},
      'featured_work_identifiers' => [],
      'captured_at' => Time.current.iso8601
    }
  end

  describe '#reset!' do
    context 'when the account is not a public demo tenant' do
      let(:account) { FactoryBot.create(:account) }

      it 'refuses to run' do
        service = described_class.new(account:)
        expect { service.reset! }.to raise_error(described_class::NotDemoTenant)
      end

      it 'does not switch into the tenant or stamp a reset time' do
        service = described_class.new(account:)
        expect(AccountElevator).not_to receive(:switch!)
        expect { service.reset! }.to raise_error(described_class::NotDemoTenant)
        expect(account.reload.last_reset_at).to be_nil
      end
    end

    context 'when no golden snapshot has been captured' do
      it 'raises MissingSnapshot' do
        service = described_class.new(account:)
        expect { service.reset! }.to raise_error(described_class::MissingSnapshot)
      end
    end

    context 'with a snapshot present' do
      subject(:service) { described_class.new(account:, health_check:) }

      let(:health_check) { nil }
      let(:steps) do
        %i[wipe_content! remove_visitor_users! restore_site!
           restore_content_blocks! restore_featured_works! import_seed!]
      end

      before do
        account.update!(demo_tenant_snapshot: snapshot)
        allow(service).to receive(:within_tenant).and_yield
        steps.each { |step| allow(service).to receive(step) }
      end

      it 'returns true and stamps last_reset_at' do
        expect(service.reset!).to be true
        expect(account.reload.last_reset_at).to be_within(1.minute).of(Time.current)
      end

      it 'wipes visitor artifacts before restoring the golden state' do
        expect(service).to receive(:wipe_content!).ordered
        expect(service).to receive(:remove_visitor_users!).ordered
        expect(service).to receive(:restore_site!).ordered
        expect(service).to receive(:restore_content_blocks!).ordered
        service.reset!
      end

      it 'skips the seed import when no seed csv path is configured' do
        expect(service).not_to receive(:import_seed!)
        service.reset!
      end

      context 'with a seed csv path' do
        subject(:service) do
          described_class.new(account:, seed_csv_path: '/tmp/seed.csv')
        end

        it 'runs the seed import' do
          expect(service).to receive(:import_seed!)
          service.reset!
        end
      end

      context 'with a health check' do
        let(:health_check) { spy('health check') }

        it 'calls it with the account' do
          service.reset!
          expect(health_check).to have_received(:call).with(account)
        end
      end

      context 'when the health check fails' do
        let(:health_check) { ->(_account) { false } }

        it 'raises and does not stamp last_reset_at' do
          expect { service.reset! }.to raise_error(described_class::HealthCheckFailed)
          expect(account.reload.last_reset_at).to be_nil
        end
      end

      context 'when a restore step raises' do
        before do
          allow(service).to receive(:restore_site!).and_raise(StandardError, 'boom')
        end

        it 'propagates the error and does not stamp last_reset_at' do
          expect { service.reset! }.to raise_error(StandardError, 'boom')
          expect(account.reload.last_reset_at).to be_nil
        end
      end
    end
  end

  describe '#snapshot!' do
    context 'when the account is not a public demo tenant' do
      let(:account) { FactoryBot.create(:account) }

      it 'refuses to run' do
        expect { described_class.new(account:).snapshot! }
          .to raise_error(described_class::NotDemoTenant)
      end
    end

    it 'captures site attributes, content blocks, and featured work identifiers' do
      service = described_class.new(account:)
      allow(service).to receive(:within_tenant).and_yield
      Site.instance.update!(application_name: 'Golden Demo')
      ContentBlock.update_block(name: 'announcement_text', value: 'Welcome')

      service.snapshot!

      snap = account.reload.demo_tenant_snapshot
      expect(snap['site']['application_name']).to eq 'Golden Demo'
      expect(snap['content_blocks']['announcement_text']).to eq 'Welcome'
      expect(snap['featured_work_identifiers']).to eq []
      expect(snap['captured_at']).to be_present
    end
  end

  describe 'import verification' do
    it 'raises ImportFailed when the importer run recorded failures' do
      service = described_class.new(account:)
      run = double('Bulkrax::ImporterRun', failed_records: 2, processed_records: 10)
      importer = double('Bulkrax::Importer', id: 1, last_run: run)
      allow(importer).to receive(:reload).and_return(importer)
      expect { service.send(:verify_import!, importer) }
        .to raise_error(described_class::ImportFailed, /failed 2 record/)
    end

    it 'raises ImportFailed when the importer recorded no run at all' do
      service = described_class.new(account:)
      importer = double('Bulkrax::Importer', id: 1, last_run: nil)
      allow(importer).to receive(:reload).and_return(importer)
      expect { service.send(:verify_import!, importer) }
        .to raise_error(described_class::ImportFailed, /no run/)
    end
  end

  describe 'a full reset against a provisioned tenant', clean: true do
    let!(:creator) { FactoryBot.create(:user, email: 'creator@demo.test') }
    let(:account) { Account.new(name: 'demoreset', public_demo_tenant: true) }
    let(:health_check) { spy('health check') }

    before do
      CreateAccount.new(account, [creator]).save
    end

    after do
      Apartment::Tenant.switch!(Apartment.default_tenant)
    end

    it 'wipes visitor artifacts, restores the golden state, keeps seed users, and is idempotent' do
      switch!(account)

      FactoryBot.create(:user, email: 'seed.depositor@demo.test')
      Site.instance.update!(application_name: 'Golden Demo')
      ContentBlock.update_block(name: 'announcement_text', value: 'Welcome to the demo')

      described_class.new(account:).snapshot!

      # Vandalize the tenant the way a visitor with shared credentials could.
      visitor = FactoryBot.create(:user, email: 'visitor@example.com')
      Site.instance.update!(application_name: 'HACKED')
      ContentBlock.update_block(name: 'announcement_text', value: 'pwned')
      ContentBlock.update_block(name: 'home_text', value: 'junk')
      FactoryBot.valkyrie_create(:generic_work_resource,
                                 title: ['Vandal work'],
                                 depositor: visitor.user_key)
      collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      Hyrax.persister.save(resource: CollectionResource.new(
        title: ['Vandal collection'],
        collection_type_gid: collection_type.to_global_id.to_s
      ))

      service = described_class.new(account:,
                                    keep_emails: ['seed.depositor@demo.test'],
                                    health_check:)
      expect(service.reset!).to be true

      switch!(account)
      expect(Hyrax.query_service.find_all_of_model(model: GenericWorkResource).count).to eq 0
      expect(Hyrax.query_service.find_all_of_model(model: CollectionResource).count).to eq 0
      expect(Site.instance.reload.application_name).to eq 'Golden Demo'
      expect(ContentBlock.block_for(name: 'announcement_text')).to eq 'Welcome to the demo'
      expect(ContentBlock.find_by(name: 'home_text')).to be_nil
      expect(User.find_by(email: 'visitor@example.com')).to be_nil
      expect(User.find_by(email: 'seed.depositor@demo.test')).to be_present
      expect(creator.reload).to be_present
      expect(creator.tenant_superadmin?).to be true
      expect(account.reload.last_reset_at).to be_present
      expect(health_check).to have_received(:call).with(account).once

      first_reset_at = account.reload.last_reset_at
      expect(service.reset!).to be true

      switch!(account)
      expect(Site.instance.reload.application_name).to eq 'Golden Demo'
      expect(Hyrax.query_service.find_all_of_model(model: GenericWorkResource).count).to eq 0
      expect(account.reload.last_reset_at).to be >= first_reset_at
    end
  end
end
