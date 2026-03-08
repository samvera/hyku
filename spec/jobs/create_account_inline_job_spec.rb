# frozen_string_literal: true

RSpec.describe CreateAccountInlineJob do
  let(:account) { FactoryBot.create(:account) }

  describe '#perform' do
    context 'when Wings is enabled' do
      before do
        allow(Hyrax.config).to receive(:disable_wings).and_return(false)
      end

      it 'calls Fedora provisioning along with other jobs' do
        expect(CreateSolrCollectionJob).to receive(:perform_now).with(account)
        expect(CreateFcrepoEndpointJob).to receive(:perform_now).with(account)
        expect(CreateRedisNamespaceJob).to receive(:perform_now).with(account)
        expect(CreateDefaultAdminSetJob).not_to receive(:perform_now) # now in callback

        described_class.perform_now(account)
      end
    end

    context 'when Wings is disabled' do
      before do
        allow(Hyrax.config).to receive(:disable_wings).and_return(true)
      end

      it 'skips Fedora provisioning and runs other jobs' do
        expect(CreateSolrCollectionJob).to receive(:perform_now).with(account)
        expect(CreateFcrepoEndpointJob).not_to receive(:perform_now)
        expect(CreateRedisNamespaceJob).to receive(:perform_now).with(account)
        expect(CreateDefaultAdminSetJob).not_to receive(:perform_now) # now in callback

        described_class.perform_now(account)
      end
    end
  end
end
