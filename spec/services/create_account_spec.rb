# frozen_string_literal: true

RSpec.describe CreateAccount, clean: true do
  subject { described_class.new(account) }

  let(:account) { FactoryBot.build(:sign_up_account) }
  let(:stubbed_admin_set) { double(AdminSetResource, id: "admin_set/id") }

  after do
    # Ensure we reset to the default tenant after each test
    Apartment::Tenant.switch!(Apartment.default_tenant)
  end

  describe '#create_tenant' do
    it 'creates a new apartment tenant' do
      expect(Apartment::Tenant).to receive(:create).with(account.tenant)
      subject.create_tenant
    end

    it 'initializes the Site configuration with a link back to the Account' do
      subject.save
      switch!(account)
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

  describe '#create_defaults' do
    let(:resource) { FactoryBot.create(:account) }
    let(:account) { CreateAccount.new(resource) }

    before do
      resource.switch!
    end

    it 'seeds the account with default data' do
      expect(RolesService).to receive(:create_default_roles!)
      expect(RolesService).to receive(:create_default_hyrax_groups_with_roles!)
      expect(Hyrax::CollectionType).to receive(:find_or_create_default_collection_type)
      expect(Hyrax::CollectionType).to receive(:find_or_create_admin_set_type)
      expect(Hyrax::AdminSetCreateService).to receive(:find_or_create_default_admin_set).and_return(stubbed_admin_set)

      account.create_defaults
    end
  end

  describe '#add_initial_users' do
    let(:resource) { FactoryBot.create(:account) }

    before do
      resource.switch!
    end

    context 'supplied users' do
      let(:user1) { FactoryBot.create(:user) }
      let(:user2) { FactoryBot.create(:user) }
      let(:account) { CreateAccount.new(resource, [user1, user2]) }

      it 'get the admin role for the account' do
        expect(user1.has_role?(:admin, Site.instance)).to eq(false)
        expect(user2.has_role?(:admin, Site.instance)).to eq(false)

        account.add_initial_users

        expect(user1.has_role?(:admin, Site.instance)).to eq(true)
        expect(user2.has_role?(:admin, Site.instance)).to eq(true)
      end

      it 'get default group memberships for the account' do
        expect(user1.hyrax_group_names).to contain_exactly('registered')
        expect(user2.hyrax_group_names).to contain_exactly('registered')

        account.add_initial_users

        expect(user1.hyrax_group_names).to contain_exactly('admin', 'registered')
        expect(user2.hyrax_group_names).to contain_exactly('admin', 'registered')
      end
    end

    context 'non-supplied users' do
      let(:user) { FactoryBot.create(:user) }
      let(:account) { CreateAccount.new(resource) }

      it 'do not change' do
        expect(user.has_role?(:admin, Site.instance)).to eq(false)

        account.add_initial_users

        expect(user.has_role?(:admin, Site.instance)).to eq(false)
      end
    end
  end

  describe '#schedule_recurring_jobs' do
    context 'when settings are enabled' do
      before do
        allow(account).to receive(:batch_email_notifications).and_return(true)
        allow(account).to receive(:depositor_email_notifications).and_return(true)
        allow(account).to receive(:analytics).and_return(true)
        allow(Hyrax.config).to receive(:analytics_reporting?).and_return(true)
      end

      it "enqueues recurring jobs" do
        [
          EmbargoAutoExpiryJob,
          LeaseAutoExpiryJob,
          BatchEmailNotificationJob,
          DepositorEmailNotificationJob,
          UserStatCollectionJob
        ].each do |klass|
          expect(account).to receive(:find_job).with(klass).and_return(false)
          expect(klass).to receive(:perform_later)
        end
        subject.schedule_recurring_jobs
      end
    end

    context 'when settings are disabled' do
      before do
        allow(account).to receive(:batch_email_notifications).and_return(false)
        allow(account).to receive(:depositor_email_notifications).and_return(false)
        allow(account).to receive(:analytics).and_return(false)
      end

      it "only enqueues embargo and lease jobs" do
        [EmbargoAutoExpiryJob, LeaseAutoExpiryJob].each do |klass|
          expect(account).to receive(:find_job).with(klass).and_return(false)
          expect(klass).to receive(:perform_later)
        end

        [
          BatchEmailNotificationJob,
          DepositorEmailNotificationJob,
          UserStatCollectionJob
        ].each do |klass|
          expect(account).not_to receive(:find_job).with(klass)
          expect(klass).not_to receive(:perform_later)
        end

        subject.schedule_recurring_jobs
      end
    end
  end
end
