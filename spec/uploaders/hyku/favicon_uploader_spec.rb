# frozen_string_literal: true

RSpec.describe Hyku::FaviconUploader do
  include ActiveSupport::Testing::TimeHelpers

  let(:account) { build(:account) }
  let(:site) { create(:site, account: account) }
  let(:uploader) { described_class.new(site, :favicon) }
  let(:file) { File.open(Rails.root.join('spec', 'fixtures', 'images', 'favicon.png').to_s) }

  describe '#filename' do
    before { uploader.store!(file) }

    it 'renames the file and its versions with the tenant id and a timestamp' do
      freeze_time do
        timestamp = Time.current.to_i
        filename = "#{account.tenant}_#{timestamp}.png"

        expect(uploader.filename).to eq(filename)
        [32, 57, 76, 96, 128, 192, 228, 196, 120, 152, 180].each do |i|
          expect(uploader.send("v#{i}").filename).to eq(filename)
        end
      end
    end
  end
end
