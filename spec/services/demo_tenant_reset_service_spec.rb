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
        %i[wipe_content! revoke_visitor_access! restore_site!
           restore_content_blocks! ensure_default_admin_set! restore_featured_works! import_seed!]
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
        expect(service).to receive(:revoke_visitor_access!).ordered
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

        # After the revocation, so visitors get no workflow roles on a new
        # admin set, and before the import, which reuses it.
        it 'ensures a default admin set between revoking access and importing' do
          expect(service).to receive(:revoke_visitor_access!).ordered
          expect(service).to receive(:ensure_default_admin_set!).ordered
          expect(service).to receive(:import_seed!).ordered
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

    context 'when a snapshot already exists' do
      before do
        account.update!(demo_tenant_snapshot: snapshot)
      end

      it 'raises SnapshotExists by default' do
        service = described_class.new(account:)
        allow(service).to receive(:within_tenant).and_yield
        expect { service.snapshot! }.to raise_error(described_class::SnapshotExists)
      end

      it 'overwrites when force: true' do
        service = described_class.new(account:)
        allow(service).to receive(:within_tenant).and_yield
        Site.instance.update!(application_name: 'Updated Golden')

        service.snapshot!(force: true)

        snap = account.reload.demo_tenant_snapshot
        expect(snap['site']['application_name']).to eq 'Updated Golden'
      end
    end
  end

  describe 'seed csv path' do
    it 'expands a %{tenant} template to the account name' do
      service = described_class.new(account:, seed_csv_path: 'tmp/imports/%{tenant}/seed/metadata.csv')
      expect(service.seed_csv_path).to eq "tmp/imports/#{account.name}/seed/metadata.csv"
    end

    it 'leaves a literal path alone' do
      service = described_class.new(account:, seed_csv_path: '/srv/seed/metadata.csv')
      expect(service.seed_csv_path).to eq '/srv/seed/metadata.csv'
    end

    it 'expands the placeholder without interpreting other percent sequences' do
      service = described_class.new(account:, seed_csv_path: 'tmp/imports/%{tenant}/100%/metadata.csv')
      expect(service.seed_csv_path).to eq "tmp/imports/#{account.name}/100%/metadata.csv"
    end

    it 'leaves a placeholder it does not support alone rather than raising' do
      service = described_class.new(account:, seed_csv_path: 'tmp/imports/%{tenant}/%{env}/metadata.csv')
      expect(service.seed_csv_path).to eq "tmp/imports/#{account.name}/%{env}/metadata.csv"
    end

    it 'leaves a nil path nil, so a reset with no seed still restores branding' do
      expect(described_class.new(account:).seed_csv_path).to be_nil
    end
  end

  describe 'draining background jobs' do
    subject(:pending_count) { described_class.new(account:).send(:pending_good_jobs) }

    let(:due) do
      { queue_name: 'default', scheduled_at: 1.minute.ago, job_class: 'Bulkrax::ImportWorkJob',
        serialized_params: { 'tenant' => account.tenant } }
    end

    # import_timeout is small on purpose: a drain regression fails the example
    # instead of busy-looping for the default hour.
    def draining(**options)
      described_class.new(account:, poll_interval: 0.05, import_timeout: 1, **options)
    end

    def enqueue(**overrides)
      GoodJob::Job.create!(active_job_id: SecureRandom.uuid, **due.merge(overrides))
    end

    it 'counts jobs due for this tenant' do
      enqueue
      expect(pending_count).to eq 1
    end

    it 'ignores Bulkrax jobs scheduled into the future, which the drain pulls forward instead' do
      enqueue(scheduled_at: 1.hour.from_now)
      expect(pending_count).to eq 0
    end

    it 'ignores another tenant, since good_jobs is not split by schema' do
      enqueue(serialized_params: { 'tenant' => 'some-other-tenant' })
      expect(pending_count).to eq 0
    end

    it 'ignores its own row, which is unfinished for as long as it runs' do
      enqueue(job_class: DemoTenantResetJob.name)
      expect(pending_count).to eq 0
    end

    it 'ignores derivatives, which can run for hours after the records exist' do
      enqueue(job_class: 'ValkyrieCreateLargeDerivativesJob')
      expect(pending_count).to eq 0
    end

    it 'ignores jobs that have already finished' do
      enqueue(finished_at: Time.current)
      expect(pending_count).to eq 0
    end

    context 'once the import has started' do
      subject(:service) { draining.tap { |s| s.instance_variable_set(:@import_started_at, 1.minute.ago) } }

      it 'ignores a job left over from before the import, such as one a dead worker never finished' do
        enqueue(created_at: 5.days.ago, performed_at: 5.days.ago)
        expect { service.send(:drain_good_job_queue!) }.not_to raise_error
      end

      it 'still waits on the jobs the import created' do
        enqueue
        expect(service.send(:pending_good_jobs)).to eq 1
      end
    end

    # The production failure was the loop, not the count: it spun for the whole
    # import_timeout because the count could never reach zero.
    it 'returns instead of spinning when only its own row remains' do
      enqueue(job_class: DemoTenantResetJob.name)
      expect { draining.send(:drain_good_job_queue!) }.not_to raise_error
    end

    it 'raises ImportFailed if the tenant queue never clears' do
      enqueue
      expect { draining.send(:drain_good_job_queue!) }
        .to raise_error(described_class::ImportFailed, /did not drain/)
    end

    it 'pulls this tenant deferred relationship jobs forward' do
      job = enqueue(scheduled_at: 10.minutes.from_now, job_class: 'Bulkrax::CreateRelationshipsJob')
      expect { draining.send(:pull_relationship_jobs_forward!) }
        .to change { job.reload.scheduled_at }
    end

    it 'leaves another tenant deferred relationship jobs alone' do
      job = enqueue(scheduled_at: 10.minutes.from_now, job_class: 'Bulkrax::CreateRelationshipsJob',
                    serialized_params: { 'tenant' => 'some-other-tenant' })
      expect { draining.send(:pull_relationship_jobs_forward!) }
        .not_to change { job.reload.scheduled_at }
    end

    # Only deferred ones count as pulled, or the outer loop never breaks.
    it 'does not count relationship jobs that are already due' do
      enqueue(job_class: 'Bulkrax::CreateRelationshipsJob')
      expect(draining.send(:pull_relationship_jobs_forward!)).to eq 0
    end

    # It rewrites scheduled_at, so anything but a relationship job losing its
    # backoff here would drag tomorrow's reset and every retry forward with it.
    it 'leaves other deferred jobs, including tomorrow reset, where they are' do
      job = enqueue(scheduled_at: 1.hour.from_now, job_class: 'EmbargoAutoExpiryJob')
      expect { draining.send(:pull_relationship_jobs_forward!) }
        .not_to change { job.reload.scheduled_at }
    end

    it 'leaves finished relationship jobs alone' do
      enqueue(scheduled_at: 10.minutes.from_now, finished_at: Time.current,
              job_class: 'Bulkrax::CreateRelationshipsJob')
      expect(draining.send(:pull_relationship_jobs_forward!)).to eq 0
    end
  end

  describe '#delete_stored_files!' do
    subject(:service) { described_class.new(account:) }

    let(:file_set) { instance_double(Hyrax::FileSet, id: 'fs-1') }
    let(:file_metadata) do
      instance_double(Hyrax::FileMetadata, file_identifier: Valkyrie::ID.new('disk://path/to/file'))
    end

    before do
      allow(Hyrax.custom_queries).to receive(:find_files).with(file_set: file_set).and_return([file_metadata])
    end

    it 'deletes stored files and file metadata for a file set' do
      expect(Valkyrie::StorageAdapter).to receive(:delete).with(id: file_metadata.file_identifier)
      expect(Hyrax.persister).to receive(:delete).with(resource: file_metadata)
      service.send(:delete_stored_files!, file_set)
    end

    it 'skips storage deletion when file_identifier is blank' do
      allow(file_metadata).to receive(:file_identifier).and_return(nil)
      expect(Valkyrie::StorageAdapter).not_to receive(:delete)
      expect(Hyrax.persister).to receive(:delete).with(resource: file_metadata)
      service.send(:delete_stored_files!, file_set)
    end

    it 'logs a warning and continues to the next file when one deletion fails' do
      good_metadata = instance_double(Hyrax::FileMetadata,
                                      file_identifier: Valkyrie::ID.new('disk://path/to/good'))
      allow(Hyrax.custom_queries).to receive(:find_files)
        .with(file_set: file_set).and_return([file_metadata, good_metadata])
      allow(Valkyrie::StorageAdapter).to receive(:delete)
        .with(id: file_metadata.file_identifier).and_raise(StandardError, 'gone')
      allow(Valkyrie::StorageAdapter).to receive(:delete).with(id: good_metadata.file_identifier)

      expect(Rails.logger).to receive(:warn).with(/failed to delete stored file/)
      expect(Hyrax.persister).not_to receive(:delete).with(resource: file_metadata)
      expect(Hyrax.persister).to receive(:delete).with(resource: good_metadata)
      service.send(:delete_stored_files!, file_set)
    end
  end

  describe 'ensuring a default admin set' do
    subject(:ensure_admin_set) { described_class.new(account:).send(:ensure_default_admin_set!) }

    def admin_sets
      Hyrax.query_service.find_all_of_model(model: Hyrax.config.admin_set_class).to_a
    end

    def admin_group_manages?(admin_set)
      Hyrax::PermissionTemplate.find_by!(source_id: admin_set.id.to_s).access_grants.exists?(
        agent_type: 'group', agent_id: ::Ability.admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE
      )
    end

    def indexed?(admin_set)
      Hyrax::SolrService.query("id:#{admin_set.id}", rows: 1).present?
    end

    context 'when the tenant has no admin set' do
      it 'creates one the admin group manages and indexes it' do
        expect { ensure_admin_set }.to change { admin_sets.size }.from(0).to(1)
        expect(admin_group_manages?(admin_sets.first)).to be true
        expect(indexed?(admin_sets.first)).to be true
      end

      it 'creates the default groups it needs' do
        Hyrax::Group.where(name: %w[admin registered public]).destroy_all
        ensure_admin_set
        expect(Hyrax::Group.where(name: %w[admin registered public]).count).to eq 3
      end

      it 'does not add a second one when run again' do
        ensure_admin_set
        described_class.new(account:).send(:ensure_default_admin_set!)
        expect(admin_sets.size).to eq 1
      end

      it 'still creates one when the saved default id points at a deleted admin set' do
        Hyrax::DefaultAdministrativeSet.create!(default_admin_set_id: 'deleted-admin-set')
        expect { ensure_admin_set }.to change { admin_sets.size }.from(0).to(1)
      end
    end

    context 'when the tenant already has an admin set' do
      let!(:existing) { FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true) }

      it 'keeps it as the only one and gives the admin group Manage on it' do
        ensure_admin_set
        expect(admin_sets.map(&:id)).to eq [existing.id]
        expect(admin_group_manages?(existing)).to be true
        expect(Hyrax::SolrService.query("id:#{existing.id}", rows: 1).first['edit_access_group_ssim'])
          .to include(::Ability.admin_group_name)
      end

      it 'indexes it again after the Solr wipe' do
        Hyrax::SolrService.wipe!
        ensure_admin_set
        expect(indexed?(existing)).to be true
      end

      it 'gives it a template and an active workflow when it has none' do
        Hyrax::PermissionTemplate.find_by!(source_id: existing.id.to_s).destroy!
        ensure_admin_set
        expect(admin_group_manages?(existing)).to be true
        expect { Sipity::Workflow.find_active_workflow_for(admin_set_id: existing.id) }.not_to raise_error
      end

      it 'keeps a saved default over any other admin set' do
        default = FactoryBot.valkyrie_create(:hyku_admin_set, with_permission_template: true)
        Hyrax::DefaultAdministrativeSet.update(default_admin_set_id: default.id)
        ensure_admin_set
        expect(admin_group_manages?(default)).to be true
        expect(admin_sets.size).to eq 2
      end

      it 'makes it the default, so the deposit form does not create another' do
        Hyrax::DefaultAdministrativeSet.create!(default_admin_set_id: 'deleted-admin-set')
        ensure_admin_set
        expect(Hyrax::DefaultAdministrativeSet.pluck(:default_admin_set_id)).to eq [existing.id.to_s]
        expect(Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id).to eq existing.id
        expect(admin_sets.size).to eq 1
      end
    end
  end

  describe 'seed importer creation' do
    subject(:importer) { service.send(:create_importer!) }

    let(:service) { described_class.new(account:, seed_csv_path: '/tmp/seed.csv') }

    before do
      allow(service).to receive(:default_admin_set_id).and_return('admin-set-1')
      allow(service).to receive(:import_user).and_return(FactoryBot.create(:user))
    end

    it 'copies the configured field mappings onto the importer' do
      # field_mapping is serialized as JSON, so a Regexp split round-trips to
      # its source string. Compare the fields covered, not the raw values.
      expect(importer.field_mapping.keys)
        .to match_array Bulkrax.field_mappings[described_class::PARSER_KLASS].keys
    end

    it 'keeps the split option that pipe-delimited seed values depend on' do
      expect(importer.field_mapping['subject']['split']).to be_present
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
      visitor_after = User.find_by(email: 'visitor@example.com')
      expect(visitor_after).to be_present
      expect(visitor_after.roles.reload).to be_empty
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
