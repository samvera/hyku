# frozen_string_literal: true

RSpec.describe CleanupSubDirectoryJob do
  let(:old_time) { Time.zone.now - 1.year }
  let(:very_old_time) { Time.zone.now - 3.years }
  let(:new_time) { Time.zone.now - 1.week }
  let(:tenant) { 'tenant-abc' }
  let(:base_dir) { '/app/samvera/uploads/tenant-abc/hyrax/uploaded_file/file' }

  let(:file_1) { "#{base_dir}/1/document.pdf" }
  let(:file_2) { "#{base_dir}/2/image.jpg" }
  let(:file_3) { "#{base_dir}/3/recent.txt" }
  let(:file_4) { "#{base_dir}/4/not_a_file" }
  let(:file_5) { "#{base_dir}/5/orphan.pdf" }
  let(:file_6) { "#{base_dir}/6/ancient.pdf" }

  let(:filenames) do
    { '1' => 'document.pdf', '2' => 'image.jpg', '3' => 'recent.txt',
      '4' => 'not_a_file', '5' => 'orphan.pdf', '6' => 'ancient.pdf' }
  end

  before do
    allow(Apartment::Tenant).to receive(:switch).with(tenant).and_yield

    allow(Dir).to receive(:glob) do |pattern|
      case pattern
      when "#{base_dir}/*"
        %w[1 2 3 4 5 6].map { |id| "#{base_dir}/#{id}" }
      when /\A#{Regexp.escape(base_dir)}\/(\d+)\/\*\z/
        id = Regexp.last_match(1)
        ["#{base_dir}/#{id}/#{filenames[id]}"]
      else
        []
      end
    end

    allow(File).to receive(:directory?) do |path|
      %w[1 2 3 4 5 6].any? { |id| path == "#{base_dir}/#{id}" }
    end

    allow(File).to receive(:file?) do |path|
      path != file_4 && [file_1, file_2, file_3, file_5, file_6].include?(path)
    end

    allow(File).to receive(:mtime).with(file_1).and_return(old_time)
    allow(File).to receive(:mtime).with(file_2).and_return(old_time)
    allow(File).to receive(:mtime).with(file_3).and_return(new_time)
    allow(File).to receive(:mtime).with(file_5).and_return(old_time)
    allow(File).to receive(:mtime).with(file_6).and_return(very_old_time)

    allow(File).to receive(:delete)
    allow(FileUtils).to receive(:rmdir)

    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '1')
                                                   .and_return(instance_double(Hyrax::UploadedFile, file_set_uri: 'http://fcrepo/rest/abc'))
    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '2')
                                                   .and_return(instance_double(Hyrax::UploadedFile, file_set_uri: 'some-uuid'))
    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '3')
                                                   .and_return(instance_double(Hyrax::UploadedFile, file_set_uri: 'some-uuid'))
    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '5')
                                                   .and_return(instance_double(Hyrax::UploadedFile, file_set_uri: nil))
    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '6')
                                                   .and_return(instance_double(Hyrax::UploadedFile, file_set_uri: nil))
  end

  it 'deletes old files that have been ingested (file_set_uri present)' do
    expect(File).to receive(:delete).with(file_1)
    expect(File).to receive(:delete).with(file_2)
    described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant)
  end

  it 'does not delete files newer than delete_ingested_after_days even if ingested' do
    expect(File).not_to receive(:delete).with(file_3)
    described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant)
  end

  it 'does not delete entries that are not files' do
    expect(File).not_to receive(:delete).with(file_4)
    described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant)
  end

  it 'does not delete old files without file_set_uri (orphaned but not old enough)' do
    expect(File).not_to receive(:delete).with(file_5)
    described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant)
  end

  it 'deletes orphaned files older than delete_all_after_days' do
    expect(File).to receive(:delete).with(file_6)
    described_class.perform_now(delete_ingested_after_days: 180,
                                directory: base_dir,
                                delete_all_after_days: 730,
                                tenant: tenant)
  end

  it 'uses configurable delete_all_after_days threshold' do
    expect(File).to receive(:delete).with(file_5)
    described_class.perform_now(delete_ingested_after_days: 180,
                                directory: base_dir,
                                delete_all_after_days: 300,
                                tenant: tenant)
  end

  it 'deletes files when no UploadedFile DB record exists and file is very old' do
    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '6').and_return(nil)
    expect(File).to receive(:delete).with(file_6)
    described_class.perform_now(delete_ingested_after_days: 180,
                                directory: base_dir,
                                delete_all_after_days: 730,
                                tenant: tenant)
  end

  it 'does not delete files when no UploadedFile DB record exists but file is not very old' do
    allow(Hyrax::UploadedFile).to receive(:find_by).with(id: '5').and_return(nil)
    expect(File).not_to receive(:delete).with(file_5)
    described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant)
  end

  describe 'cleaning up empty directories' do
    before do
      allow(File).to receive(:directory?).with("#{base_dir}/1").and_return(true)
      allow(File).to receive(:directory?).with("#{base_dir}/2").and_return(true)
      allow(File).to receive(:directory?).with("#{base_dir}/3").and_return(true)
      allow(FileUtils).to receive(:rmdir)
        .with("#{base_dir}/2")
        .and_raise(Errno::ENOTEMPTY)
    end

    it 'attempts to remove empty upload ID directories' do
      expect(FileUtils).to receive(:rmdir).with("#{base_dir}/1")
      expect(FileUtils).to receive(:rmdir).with("#{base_dir}/2")
      expect(FileUtils).to receive(:rmdir).with("#{base_dir}/3")

      described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant)
    end

    it 'continues when a directory is not empty' do
      expect { described_class.perform_now(delete_ingested_after_days: 180, directory: base_dir, tenant: tenant) }
        .not_to raise_error
    end
  end
end
