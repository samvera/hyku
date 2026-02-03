# frozen_string_literal: true

RSpec.describe Hyku::AvatarUploader do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { build(:account) }
  let(:site) { create(:site, account: account) }
  let(:uploader) { described_class.new(site, :banner_image) }
  let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'images', 'world.png').to_s) }

  describe '#filename' do
    before { uploader.store!(file) }

    it 'renames the file with the tenant id and a timestamp' do
      freeze_time do
        timestamp = Time.current.to_i
        uploader.store!(file)
        expect(uploader.filename).to eq("#{account.tenant}_#{timestamp}.png")
      end
    end
  end
end
