# frozen_string_literal: true

RSpec.describe AccountElevator do
  subject { described_class.new(nil) }

  let(:request) { double(host: 'example.com') }
  let(:bad_request) { double(host: 'new.example.com') }
  let!(:account) { FactoryBot.create(:account, cname: 'example.com') }

  describe '#parse_tenant_name' do
    it 'retrieves the tenant name for the account' do
      expect(subject.parse_tenant_name(request)).to eq account.tenant
    end

    it 'returns nil if no tenant is found' do
      expect(subject.parse_tenant_name(bad_request)).to be_nil
    end
  end
end
