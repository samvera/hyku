# frozen_string_literal: true

RSpec.describe BrandingMigrationCopyJob do
  let(:tenant) { 'test-tenant-uuid' }
  let(:site_id) { 1 }
  let(:identifier) { 'banner.png' }

  let(:dest_dir) do
    Hyrax.config.branding_path.join(tenant, 'site', 'banner_images')
  end
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
    allow(Dir).to receive(:exist?).and_return(false)
    allow(Dir).to receive(:glob).and_return([])
    allow(FileUtils).to receive(:mkdir_p)
    allow(FileUtils).to receive(:cp)
  end

  context 'when a legacy directory exists' do
    let(:legacy_file) { File.join(legacy_dir, identifier) }

    before do
      allow(Dir).to receive(:exist?).with(legacy_dir).and_return(true)
      allow(Dir).to receive(:glob).with("#{legacy_dir}/**/*").and_return([legacy_file])
      allow(File).to receive(:directory?).with(legacy_file).and_return(false)
      allow(File).to receive(:file?).with(legacy_file).and_return(true)
      allow(Pathname).to receive(:new).and_call_original
    end

    it 'copies files from the legacy directory' do
      expect(FileUtils).to receive(:cp).at_least(:once)
      described_class.new.perform(tenant: tenant)
    end
  end

  context 'when no legacy directory exists' do
    it 'does not copy anything' do
      expect(FileUtils).not_to receive(:cp)
      described_class.new.perform(tenant: tenant)
    end

    it 'does not raise' do
      expect { described_class.new.perform(tenant: tenant) }.not_to raise_error
    end
  end
end
