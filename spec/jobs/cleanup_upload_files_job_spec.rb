# frozen_string_literal: true

RSpec.describe CleanupUploadFilesJob do
  let(:hex_dir_ff) { '/app/samvera/uploads/ff' }
  let(:hex_dir_00) { '/app/samvera/uploads/00' }
  let(:hex_dir_ab) { '/app/samvera/uploads/ab' }
  let(:uuid_tenant_dir) { '/app/samvera/uploads/56e0eb81-c2d5-4d5d-9171-b251bf7299a4' }
  let(:uploaded_collection_thumbnails_dir) { '/app/samvera/uploads/uploaded_collection_thumbnails' }
  let(:identity_provider_dir) { '/app/samvera/uploads/identity_provider' }
  let(:hyrax_uploaded_file_dir) { '/app/samvera/uploads/hyrax' }

  let(:all_top_level_entries) do
    [
      hex_dir_ff, hex_dir_00, hex_dir_ab,
      uuid_tenant_dir,
      uploaded_collection_thumbnails_dir,
      identity_provider_dir,
      hyrax_uploaded_file_dir,
      '/app/samvera/uploads/somefile'
    ]
  end

  before do
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with('/app/samvera/uploads/*').and_return(all_top_level_entries)
    allow(File).to receive(:directory?).and_call_original
    [hex_dir_ff, hex_dir_00, hex_dir_ab, uuid_tenant_dir,
     uploaded_collection_thumbnails_dir, identity_provider_dir, hyrax_uploaded_file_dir].each do |dir|
      allow(File).to receive(:directory?).with(dir).and_return(true)
    end
    allow(File).to receive(:directory?).with('/app/samvera/uploads/somefile').and_return(false)
  end

  it 'spawns child jobs only for hex pair-tree directories (00-ff)' do
    expect { described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob).exactly(3).times
  end

  it 'does not create CleanupSubDirectoryJob for tenant UUID directories (site/banner_images, etc.)' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads')
    end.not_to have_enqueued_job(CleanupSubDirectoryJob).with(directory: uuid_tenant_dir)
  end

  it 'does not create CleanupSubDirectoryJob for uploaded_collection_thumbnails directory' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads')
    end.not_to have_enqueued_job(CleanupSubDirectoryJob).with(directory: uploaded_collection_thumbnails_dir)
  end

  it 'does not create CleanupSubDirectoryJob for identity_provider directory (LogoUploader)' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads')
    end.not_to have_enqueued_job(CleanupSubDirectoryJob).with(directory: identity_provider_dir)
  end

  it 'does not create CleanupSubDirectoryJob for hyrax directory (UploadedFile cache)' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads')
    end.not_to have_enqueued_job(CleanupSubDirectoryJob).with(directory: hyrax_uploaded_file_dir)
  end

  it 'passes delete_all_after_days parameter to child jobs' do
    expect do
      described_class.perform_now(delete_ingested_after_days: 180,
                                  uploads_path: '/app/samvera/uploads',
                                  delete_all_after_days: 365)
    end.to have_enqueued_job(CleanupSubDirectoryJob)
      .with(
        delete_ingested_after_days: 180,
        directory: hex_dir_ff,
        delete_all_after_days: 365
      )
  end

  it 'uses default delete_all_after_days of 730 when not specified' do
    expect { described_class.perform_now(delete_ingested_after_days: 180, uploads_path: '/app/samvera/uploads') }
      .to have_enqueued_job(CleanupSubDirectoryJob)
      .with(
        delete_ingested_after_days: 180,
        directory: hex_dir_ff,
        delete_all_after_days: 730
      )
  end
end
