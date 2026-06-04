# frozen_string_literal: true

RSpec.describe BrandingMigrationCleanupJob do
  let(:tenant) { 'test-tenant-uuid' }
  let(:site_id) { 1 }
  let(:identifier) { 'banner.png' }

  let(:dest_dir) do
    Hyrax.config.branding_path.join(tenant, 'site', 'banner_images')
  end
  let(:original_file) { dest_dir.join('original', identifier) }
  let(:legacy_dir) do
    File.join(Hyrax.config.upload_path.call.to_s, 'site', 'banner_images', site_id.to_s)
  end

  let(:site) { instance_double(Site, id: site_id) }
  let(:uploader) { instance_double(Hyku::AvatarUploader, identifier: identifier) }

  before do
    allow(Apartment::Tenant).to receive(:switch).with(tenant).and_yield
    allow(Apartment::Tenant).to receive(:current).and_return(tenant)
    allow(Site).to receive(:instance).and_return(site)
    allow(Site).to receive(:account).and_return(nil)
    BrandingMigrationPaths::BRANDING_COLUMNS.each do |col|
      allow(site).to receive(:send).with(col).and_return(
        col == :banner_image ? uploader : instance_double(Hyku::AvatarUploader, identifier: nil)
      )
    end
    allow(File).to receive(:exist?).and_return(false)
    allow(Dir).to receive(:exist?).and_return(false)
    allow(Dir).to receive(:glob).and_return([])
    allow(File).to receive(:file?).and_return(false)
    allow(FileUtils).to receive(:rm_rf)
  end

  context 'when original exists at new path and legacy directory exists' do
    before do
      allow(File).to receive(:exist?).with(original_file).and_return(true)
      allow(Dir).to receive(:exist?).with(legacy_dir).and_return(true)
      allow(Dir).to receive(:glob).with("#{legacy_dir}/**/*").and_return([])
    end

    it 'removes the legacy directory' do
      expect(FileUtils).to receive(:rm_rf).with(legacy_dir)
      described_class.new.perform(tenant: tenant)
    end
  end

  context 'when original does not exist at new path' do
    before do
      allow(File).to receive(:exist?).with(original_file).and_return(false)
      allow(Dir).to receive(:exist?).with(legacy_dir).and_return(true)
    end

    it 'does not remove the legacy directory' do
      expect(FileUtils).not_to receive(:rm_rf)
      described_class.new.perform(tenant: tenant)
    end

    it 'does not raise' do
      expect { described_class.new.perform(tenant: tenant) }.not_to raise_error
    end
  end

  context 'when legacy directory does not exist' do
    before { allow(File).to receive(:exist?).with(original_file).and_return(true) }

    it 'does not raise' do
      expect { described_class.new.perform(tenant: tenant) }.not_to raise_error
    end

    it 'does not call rm_rf' do
      expect(FileUtils).not_to receive(:rm_rf)
      described_class.new.perform(tenant: tenant)
    end
  end
end
