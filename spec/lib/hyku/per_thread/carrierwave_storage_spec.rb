# frozen_string_literal: true

RSpec.describe Hyku::PerThread, 'CarrierWave storage' do
  let(:account_a) { FactoryBot.build(:sign_up_account) }
  let(:account_b) { FactoryBot.build(:sign_up_account) }

  before do
    account_a.settings['s3_bucket'] = 'bucket-a'
    account_b.settings['file_acl'] = 'false'
    [account_a, account_b].each { |account| CreateAccount.new(account, []).save }
  end

  after { Apartment::Tenant.switch!(Apartment.default_tenant) }

  # A thread's DB connection can't see rows inside the main thread's open transaction.
  it "keeps each tenant's upload storage settings", truncation: true do
    results = results_per_tenant([account_a, account_b]) do
      [Hyku::AvatarUploader.permissions, Hyrax::UploadedFileUploader.storage, Hyrax::UploadedFileUploader.aws_bucket,
       Hyrax::UploadedFileUploader.aws_acl]
    end

    expect(results).to eq(account_a => [[0o644, CarrierWave::Storage::AWS, 'bucket-a', 'bucket-owner-full-control']], account_b => [[nil, CarrierWave::Storage::File, nil, nil]])
  end
end
