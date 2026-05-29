# frozen_string_literal: true

RSpec.describe UploadsCleanupService do
  subject(:service) do
    described_class.new(
      delete_ingested_after_days: 180,
      delete_all_after_days: 730,
      extra_upload_paths: extra_upload_paths,
      include_orphaned_tenant_dirs: include_orphaned
    )
  end

  let(:extra_upload_paths) { [] }
  let(:include_orphaned) { false }

  let(:tenant_id) { '11111111-1111-1111-1111-111111111111' }
  let(:account) { instance_double(Account, tenant: tenant_id) }
  let(:base_path) { '/app/samvera/uploads' }
  let(:tenant_path) { "#{base_path}/#{tenant_id}" }
  let(:staging_dir) { "#{tenant_path}/hyrax/uploaded_file/file" }

  before do
    allow(CleanupUploadFilesJob).to receive(:perform_later)
    allow(Account).to receive(:find_each).and_yield(account)
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(staging_dir).and_return(true)
    allow($stdout).to receive(:puts)

    ENV['HYRAX_UPLOAD_PATH'] = base_path
  end

  after { ENV.delete('HYRAX_UPLOAD_PATH') }

  describe '#run' do
    context 'when the tenant has a local staging directory' do
      it 'enqueues CleanupUploadFilesJob with the correct parameters' do
        service.run

        expect(CleanupUploadFilesJob).to have_received(:perform_later).with(
          delete_ingested_after_days: 180,
          uploads_path: tenant_path,
          delete_all_after_days: 730,
          tenant: tenant_id
        )
      end
    end

    context 'when the tenant has no local staging directory' do
      before { allow(Dir).to receive(:exist?).with(staging_dir).and_return(false) }

      it 'does not enqueue a job' do
        service.run

        expect(CleanupUploadFilesJob).not_to have_received(:perform_later)
      end
    end

    context 'when the tenant now uses S3 but has leftover local staging files' do
      # Previously the rake task skipped S3 tenants entirely; we must still clean local leftovers.
      it 'enqueues cleanup for the local path regardless of S3 config' do
        service.run

        expect(CleanupUploadFilesJob).to have_received(:perform_later).with(
          hash_including(uploads_path: tenant_path, tenant: tenant_id)
        )
      end
    end

    context 'when HYRAX_UPLOAD_PATH is not set' do
      let(:rails_uploads) { Rails.root.join('public', 'uploads', tenant_id).to_s }
      let(:rails_staging) { File.join(rails_uploads, 'hyrax/uploaded_file/file') }

      before do
        ENV.delete('HYRAX_UPLOAD_PATH')
        allow(Dir).to receive(:exist?).with(staging_dir).and_return(false)
        allow(Dir).to receive(:exist?).with(rails_staging).and_return(true)
      end

      it 'falls back to public/uploads/{tenant}' do
        service.run

        expect(CleanupUploadFilesJob).to have_received(:perform_later).with(
          hash_including(uploads_path: rails_uploads)
        )
      end
    end

    context 'with EXTRA_UPLOAD_PATHS' do
      let(:legacy_base) { '/old/samvera/uploads' }
      let(:extra_upload_paths) { [legacy_base] }
      let(:other_tenant_id) { '22222222-2222-2222-2222-222222222222' }
      let(:other_tenant_path) { "#{legacy_base}/#{other_tenant_id}" }
      let(:other_staging_dir) { "#{other_tenant_path}/hyrax/uploaded_file/file" }

      before do
        allow(Dir).to receive(:exist?).with(legacy_base).and_return(true)
        allow(Dir).to receive(:exist?).with(other_staging_dir).and_return(true)
        allow(Dir).to receive(:children).with(legacy_base).and_return([other_tenant_id])
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(other_tenant_path).and_return(true)
        allow(Account).to receive(:pluck).with(:tenant).and_return([tenant_id, other_tenant_id])
      end

      it 'enqueues cleanup for UUID dirs matching known tenants' do
        service.run

        expect(CleanupUploadFilesJob).to have_received(:perform_later).with(
          hash_including(uploads_path: other_tenant_path, tenant: other_tenant_id)
        )
      end

      it 'does not enqueue for non-UUID directory names' do
        allow(Dir).to receive(:children).with(legacy_base).and_return(['not-a-uuid', 'cache', other_tenant_id])
        allow(File).to receive(:directory?).with("#{legacy_base}/not-a-uuid").and_return(true)
        allow(File).to receive(:directory?).with("#{legacy_base}/cache").and_return(true)

        service.run

        expect(CleanupUploadFilesJob).to have_received(:perform_later).once
      end

      context 'when the same path appears in both the main loop and extra paths' do
        let(:extra_upload_paths) { [base_path] }

        before do
          allow(Dir).to receive(:children).with(base_path).and_return([tenant_id])
          allow(File).to receive(:directory?).with(tenant_path).and_return(true)
          allow(Account).to receive(:pluck).with(:tenant).and_return([tenant_id])
        end

        it 'enqueues the path only once' do
          service.run

          expect(CleanupUploadFilesJob).to have_received(:perform_later).once
        end
      end

      context 'when there are files stored directly under the base path (null/empty tenant context)' do
        # When Apartment::Tenant.current returned nil/empty at upload time, File.join collapses
        # the tenant segment and CarrierWave writes staging files straight into the upload root,
        # producing directories like /app/samvera/uploads/hyrax/uploaded_file/file/97/ instead of
        # /app/samvera/uploads/{tenant-uuid}/hyrax/uploaded_file/file/97/.
        let(:null_tenant_staging) { "#{legacy_base}/hyrax/uploaded_file/file" }

        before do
          allow(Dir).to receive(:children).with(legacy_base).and_return([])
          allow(Dir).to receive(:exist?).with(null_tenant_staging).and_return(true)
          allow(Account).to receive(:pluck).with(:tenant).and_return([tenant_id])
        end

        context 'when include_orphaned_tenant_dirs is false' do
          it 'does not enqueue cleanup for the base path' do
            service.run

            expect(CleanupUploadFilesJob).not_to have_received(:perform_later).with(
              hash_including(uploads_path: legacy_base)
            )
          end
        end

        context 'when include_orphaned_tenant_dirs is true' do
          let(:include_orphaned) { true }

          it 'enqueues cleanup for the base path with nil tenant' do
            service.run

            expect(CleanupUploadFilesJob).to have_received(:perform_later).with(
              delete_ingested_after_days: 730,
              uploads_path: legacy_base,
              delete_all_after_days: 730,
              tenant: nil
            )
          end
        end
      end

      context 'when the extra path directory does not exist' do
        let(:extra_upload_paths) { ['/nonexistent/path'] }

        before { allow(Dir).to receive(:exist?).with('/nonexistent/path').and_return(false) }

        it 'skips gracefully without raising' do
          expect { service.run }.not_to raise_error
        end

        it 'does not enqueue jobs for the missing path' do
          service.run

          expect(CleanupUploadFilesJob).to have_received(:perform_later).once # main loop only
        end
      end

      context 'with orphaned tenant dirs (tenant no longer in Account table)' do
        let(:orphaned_id) { '33333333-3333-3333-3333-333333333333' }
        let(:orphaned_path) { "#{legacy_base}/#{orphaned_id}" }
        let(:orphaned_staging) { "#{orphaned_path}/hyrax/uploaded_file/file" }

        before do
          allow(Dir).to receive(:children).with(legacy_base).and_return([orphaned_id])
          allow(File).to receive(:directory?).with(orphaned_path).and_return(true)
          allow(Dir).to receive(:exist?).with(orphaned_staging).and_return(true)
          allow(Account).to receive(:pluck).with(:tenant).and_return([tenant_id])
        end

        context 'when include_orphaned_tenant_dirs is false (default)' do
          it 'skips the orphaned directory' do
            service.run

            expect(CleanupUploadFilesJob).not_to have_received(:perform_later).with(
              hash_including(uploads_path: orphaned_path)
            )
          end
        end

        context 'when include_orphaned_tenant_dirs is true' do
          let(:include_orphaned) { true }

          it 'enqueues cleanup with nil tenant and delete_all_after_days as both thresholds' do
            service.run

            expect(CleanupUploadFilesJob).to have_received(:perform_later).with(
              delete_ingested_after_days: 730,
              uploads_path: orphaned_path,
              delete_all_after_days: 730,
              tenant: nil
            )
          end

          context 'when the orphaned staging directory does not exist' do
            before { allow(Dir).to receive(:exist?).with(orphaned_staging).and_return(false) }

            it 'skips the orphaned directory' do
              service.run

              expect(CleanupUploadFilesJob).not_to have_received(:perform_later).with(
                hash_including(uploads_path: orphaned_path)
              )
            end
          end
        end
      end
    end
  end
end
