# frozen_string_literal: true

RSpec.describe 'Hyrax S3 migration tenant scope' do
  before { skip 'requires a Hyrax release that includes Hyrax::S3Migration' unless defined?(Hyrax::S3Migration) }

  it 'scopes manifest entries to the current tenant' do
    allow(Site).to receive(:account).and_return(double('account', cname: 'one.example.com'))

    expect(Hyrax::S3Migration.scope).to eq 'one.example.com'
  end

  it 'has no scope outside a tenant' do
    allow(Site).to receive(:account).and_return(nil)

    expect(Hyrax::S3Migration.scope).to be_nil
  end
end
