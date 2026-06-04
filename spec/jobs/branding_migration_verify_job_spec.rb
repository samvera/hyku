# frozen_string_literal: true

RSpec.describe BrandingMigrationVerifyJob do
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
  end

  context 'when the original file exists at the new path' do
    before { allow(File).to receive(:exist?).with(original_file).and_return(true) }

    it 'does not raise' do
      expect { described_class.new.perform(tenant: tenant) }.not_to raise_error
    end
  end

  context 'when the original is missing but a legacy directory exists' do
    before do
      allow(File).to receive(:exist?).with(original_file).and_return(false)
      allow(Dir).to receive(:exist?).with(legacy_dir).and_return(true)
    end

    it 'does not raise' do
      expect { described_class.new.perform(tenant: tenant) }.not_to raise_error
    end
  end

  context 'when the file is missing from all locations' do
    before { allow(File).to receive(:exist?).with(original_file).and_return(false) }

    it 'does not raise' do
      expect { described_class.new.perform(tenant: tenant) }.not_to raise_error
    end
  end
end
