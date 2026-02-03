# frozen_string_literal: true

RSpec.describe Hyku::LogoUploader do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { build(:account) }
  let(:site) { create(:site, account: account) }
  let(:uploader) { described_class.new(site, :logo_image) }
  let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'images', 'world.png').to_s) }

  describe '#filename' do
    it 'renames the file and its versions with the tenant id and a timestamp' do
      freeze_time do
        timestamp = Time.current.to_i
        uploader.store!(file)
        filename = "#{account.tenant}_#{timestamp}.png"

        expect(uploader.filename).to eq(filename)
        expect(uploader.medium.filename).to eq(filename)
        expect(uploader.thumb.filename).to eq(filename)
      end
    end
  end
end
