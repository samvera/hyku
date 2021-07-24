# frozen_string_literal: true

RSpec.describe CreateAccount do
  subject { described_class.new(account) }

  let(:account) { FactoryBot.build(:sign_up_account) }

  describe '#create_tenant' do
    it 'creates a new apartment tenant' do
      expect(Apartment::Tenant).to receive(:create).with(account.tenant)
      subject.create_tenant
    end

    it 'initializes the Site configuration with a link back to the Account' do
      expect(Apartment::Tenant).to receive(:create).with(any_args) do |&block|
        block.call
      end
      expect(AdminSet).to receive(:find_or_create_default_admin_set_id)
      subject.save
      expect(Site.reload.account).to eq account
    end
  end

  describe '#create_account_inline' do
    it 'runs account creation jobs' do
      expect(CreateAccountInlineJob).to receive(:perform_now).with(account)
      subject.create_account_inline
    end
  end

  describe '#save' do
    let(:resource1) { Account.new(name: 'example') }
    let(:resource2) { Account.new(name: 'example') }
    let(:account1) { CreateAccount.new(resource1) }
    let(:account2) { CreateAccount.new(resource2) }

    before do
      allow(account1).to receive(:create_external_resources).and_return true
      allow(account2).to receive(:create_external_resources).and_return true
    end

    it 'prevents duplicate accounts' do
      expect(account1.save).to be true
      expect(account2.save).to be false
      expect(account2.account.errors).to match a_hash_including(:"domain_names.cname")
    end
  end

  describe '#schedule_recurring_jobs' do
    it "Enques Embargo and Lease Expiry jobs" do
      expect(EmbargoAutoExpiryJob).to receive(:perform_later).with(account)
      expect(LeaseAutoExpiryJob).to receive(:perform_later).with(account)
      subject.schedule_recurring_jobs
    end
  end
end
