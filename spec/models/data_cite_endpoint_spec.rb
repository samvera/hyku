# frozen_string_literal: true

RSpec.describe DataCiteEndpoint do
  subject(:endpoint) { described_class.new mode: 'test', prefix: '10.1234', username: 'user123', password: 'pass123' }

  describe '.options' do
    it 'uses the configured application settings' do
      expect(endpoint.options[:mode]).to eq 'test'
      expect(endpoint.options[:prefix]).to eq '10.1234'
      expect(endpoint.options[:username]).to eq 'user123'
      expect(endpoint.options[:password]).to eq 'pass123'
    end
  end

  describe '#ping' do
    # TODO: make this test better when #ping has a real implementation
    it 'returns true' do
      expect(endpoint.ping).to eq true
    end
  end

  describe '#remove!' do
    it 'destroys the endpoint' do
      expect { endpoint.remove! }.to change(endpoint, :destroyed?).from(false).to(true)
    end

    context 'cascades from account' do
      let(:account) { Account.create(name: "test") }
      let!(:endpoint) { account.create_data_cite_endpoint }

      it 'destroys the endpoint' do
        expect(account.data_cite_endpoint).to be_persisted
        expect { account.destroy }.to change(endpoint, :destroyed?).from(false).to(true)
      end
    end
  end
end
