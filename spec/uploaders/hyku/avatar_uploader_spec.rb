# frozen_string_literal: true

RSpec.describe Hyku::AvatarUploader do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { build(:account) }
  let(:site) { create(:site, account: account) }
  let(:uploader) { described_class.new(site, :banner_image) }
  let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'images', 'world.png').to_s) }

  describe '#filename' do
    before { uploader.store!(file) }

    it 'renames the file and its versions with the tenant id and a timestamp' do
      freeze_time do
        timestamp = Time.current.to_i
        filename = "#{account.tenant}_#{timestamp}.png"

        expect(uploader.filename).to eq(filename)
        expect(uploader.medium.filename).to eq(filename)
        expect(uploader.thumb.filename).to eq(filename)
      end
    end
  end

  describe 'storage location' do
    before { uploader.store!(file) }

    # Banner images (and other site branding assets) must be stored under
    # Hyrax.config.branding_path, not the temporary upload staging directory.
    # The upload staging directory can be cleaned out by CleanupUploadFilesJob,
    # which would cause permanent data loss for branding assets.
    it 'stores banner images in the branding directory, not the temporary uploads directory' do
      branding_path = Hyrax.config.branding_path.to_s
      expect(uploader.current_path).to start_with(branding_path),
        "Expected banner image to be stored under the branding directory (#{branding_path}), " \
        "but it was stored at #{uploader.current_path}. " \
        "Site branding images must live in a permanent location, not the temporary uploads staging directory."
    end

    it 'does not store banner images in the configured uploads directory or subdirectories' do
      upload_path = Hyrax.config.upload_path.call.to_s
      expect(uploader.current_path).not_to start_with(upload_path),
        "Expected banner image to be stored outside the uploads directory (#{upload_path}), " \
        "but it was stored at #{uploader.current_path}."
    end
  end

  describe 'legacy fallback' do
    let(:identifier) { 'legacy_banner.png' }
    let(:legacy_path) do
      File.join(
        Hyrax.config.upload_path.call.to_s,
        'site', 'banner_images', site.id.to_s, identifier
      )
    end

    before do
      site.update_column(:banner_image, identifier) # rubocop:disable Rails/SkipsModelValidations
      FileUtils.mkdir_p(File.dirname(legacy_path))
      FileUtils.touch(legacy_path)
    end

    after { FileUtils.rm_f(legacy_path) }

    it 'falls back to the legacy upload path when the file is not at the new branding path' do
      expect(Deprecation).to receive(:warn).with(anything, /legacy path/)
      uploader.retrieve_from_store!(identifier)
      expect(uploader.file.path).to eq(legacy_path)
    end

    it 'does not warn when the file already exists at the new branding path' do
      uploader.store!(file)
      expect(Deprecation).not_to receive(:warn)
      uploader.retrieve_from_store!(uploader.identifier)
    end
  end
end
