RSpec.describe CreateAccountInlineJob do
  let(:account) { FactoryBot.create(:account) }

  describe '#perform' do
    it 'calls other jobs synchronously' do
      expect(CreateSolrCollectionJob).to receive(:perform_now).with(account)
      expect(CreateFcrepoEndpointJob).to receive(:perform_now).with(account)
      expect(CreateRedisNamespaceJob).to receive(:perform_now).with(account)
      expect(CreateDefaultAdminSetJob).not_to receive(:perform_now) # now in callback
      described_class.perform_now(account)
    end
  end
end
