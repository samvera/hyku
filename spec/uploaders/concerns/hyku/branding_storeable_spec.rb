# frozen_string_literal: true

RSpec.describe Hyku::BrandingStoreable do
  let(:account) { build(:account) }
  let(:site) { create(:site, account: account) }
  let(:uploader) { Hyku::AvatarUploader.new(site, :banner_image) }
  let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'images', 'world.png').to_s) }

  describe '#store_dir' do
    it 'is rooted under Hyrax.config.branding_path' do
      expect(uploader.store_dir).to start_with(Hyrax.config.branding_path.to_s)
    end

    it 'is not rooted under Hyrax.config.upload_path' do
      expect(uploader.store_dir).not_to start_with(Hyrax.config.upload_path.call.to_s)
    end

    it 'includes the model class and attachment segments' do
      expect(uploader.store_dir).to include('site', 'banner_images')
    end
  end

  describe '#retrieve_from_store!' do
    let(:identifier) { 'legacy_banner.png' }

    context 'when the file exists at a legacy upload path (no style subdir)' do
      let(:legacy_path) do
        File.join(Hyrax.config.upload_path.call.to_s, 'site', 'banner_images', site.id.to_s, identifier)
      end

      before do
        site.update_column(:banner_image, identifier) # rubocop:disable Rails/SkipsModelValidations
        FileUtils.mkdir_p(File.dirname(legacy_path))
        FileUtils.touch(legacy_path)
      end

      after { FileUtils.rm_f(legacy_path) }

      it 'serves the file from the legacy path' do
        allow(Deprecation).to receive(:warn)
        uploader.retrieve_from_store!(identifier)
        expect(uploader.file.path).to eq(legacy_path)
      end

      it 'emits a deprecation warning that mentions the legacy path' do
        expect(Deprecation).to receive(:warn).with(anything, /legacy path/)
        uploader.retrieve_from_store!(identifier)
      end

      it 'instructs the operator to run migrate:copy' do
        expect(Deprecation).to receive(:warn).with(anything, /migrate:copy/)
        uploader.retrieve_from_store!(identifier)
      end
    end

    context 'when the file exists at a legacy upload path with original style subdir' do
      let(:legacy_path) do
        File.join(Hyrax.config.upload_path.call.to_s, 'site', 'banner_images', site.id.to_s, 'original', identifier)
      end

      before do
        site.update_column(:banner_image, identifier) # rubocop:disable Rails/SkipsModelValidations
        FileUtils.mkdir_p(File.dirname(legacy_path))
        FileUtils.touch(legacy_path)
      end

      after { FileUtils.rm_f(legacy_path) }

      it 'serves the file from the legacy path' do
        allow(Deprecation).to receive(:warn)
        uploader.retrieve_from_store!(identifier)
        expect(uploader.file.path).to eq(legacy_path)
      end
    end

    context 'when the file does not exist at any legacy path' do
      before { site.update_column(:banner_image, identifier) } # rubocop:disable Rails/SkipsModelValidations

      it 'does not raise' do
        expect { uploader.retrieve_from_store!(identifier) }.not_to raise_error
      end

      it 'does not emit a deprecation warning' do
        expect(Deprecation).not_to receive(:warn)
        uploader.retrieve_from_store!(identifier)
      end
    end

    context 'when the file already exists at the new branding path' do
      before { uploader.store!(file) }

      it 'does not emit a deprecation warning' do
        expect(Deprecation).not_to receive(:warn)
        uploader.retrieve_from_store!(uploader.identifier)
      end
    end
  end
end
