# frozen_string_literal: true

# Test-only job used to exercise the real ActiveJobTenant#perform_now wrapper
# (config/initializers/apartment_activejob.rb includes it into ActiveJob::Base,
# so every real job gets this same tenant-switching behavior for free).
class SiteNameCapturingJob < ApplicationJob
  def perform
    Site.instance.application_name
  end
end

RSpec.describe Site, type: :model do
  let(:admin1) { FactoryBot.create(:user, email: 'bob@was_here.net') }
  let(:admin2) { FactoryBot.create(:user, email: 'jane@was_here.net') }
  let(:admin3) { FactoryBot.create(:user, email: 'i@was_here.net') }

  # Apartment's :switch callback calls this, so a cache that survives holds the
  # previous tenant's rows -- in an in-process tenant loop such as a rake reindex,
  # one tenant's ids would resolve against another's labels.
  describe ".reset!" do
    it "clears the per-request caches that hold tenant rows" do
      RequestStore.store[:controlled_vocabulary_label_maps] = { 'licenses' => { 'id' => 'Tenant A' } }
      RequestStore.store[:controlled_vocabulary_resolvable] = { 'tenant_a_only_vocab' => true }

      described_class.reset!

      expect(RequestStore.store).not_to have_key(:controlled_vocabulary_label_maps)
      expect(RequestStore.store).not_to have_key(:controlled_vocabulary_resolvable)
    end
  end

  describe ".instance" do
    let(:request_store_mock) { {} }
    before do
      allow(RequestStore).to receive(:store).and_return(request_store_mock)
    end
    context "on global tenant" do
      before do
        allow(Account).to receive(:global_tenant?).and_return true
      end

      it "is a NilSite" do
        expect(described_class.instance).to be_an_instance_of(NilSite)
      end
    end

    context "on a specific tenant" do
      it "is a singleton site" do
        expect(described_class.instance).to eq(described_class.instance)
      end
      it 'only queries the database once across multiple calls in the same request' do
        expect(described_class).to receive(:first_or_create).once.and_call_original

        3.times { described_class.instance }
      end

      it 'returns the same object across multiple calls' do
        first = described_class.instance
        second = described_class.instance

        expect(first).to equal(second)
      end

      it 'queries again after RequestStore is cleared (simulating a new request)' do
        local_request_store_mock = {}
        allow(RequestStore).to receive(:store).and_return(local_request_store_mock)
        described_class.instance
        expect(local_request_store_mock.keys).to eq([:site_instance])
        local_request_store_mock.delete(:site_instance)
        expect(Site).to receive(:first_or_create).once.and_call_original
        described_class.instance
      end
    end
    describe '.instance across an in-process tenant switch' do
      after { Apartment::Tenant.switch!(Apartment.default_tenant) }

      let(:old_account) { FactoryBot.build(:sign_up_account) }
      let(:new_account) { FactoryBot.build(:sign_up_account) }

      before do
        CreateAccount.new(old_account).save
        CreateAccount.new(new_account).save

        Apartment::Tenant.switch!(old_account.tenant)
        Site.instance.update!(application_name: 'old site')

        Apartment::Tenant.switch!(new_account.tenant)
        Site.instance.update!(application_name: 'new site')
      end

      it 'does not return a stale Site after switching tenants within the same thread' do
        Apartment::Tenant.switch!(old_account.tenant)
        expect(described_class.instance.application_name).to eq('old site')

        Apartment::Tenant.switch!(new_account.tenant)
        expect(described_class.instance.application_name).to eq('new site')
      end

      # RequestStore.store is Thread.current[:request_store] (pure thread-local), so
      # this test needs real accounts visible to a *different* DB connection than the
      # one holding the example's own open transaction - truncation instead of the
      # suite's default transactional strategy for model specs.
      it 'does not leak a memoized Site across concurrent threads for different tenants', truncation: true do
        seen_names = Queue.new
        [[old_account, 'old site'], [new_account, 'new site']].map do |account, expected_name|
          Thread.new do
            Apartment::Tenant.switch!(account.tenant)
            names = Array.new(20) { Site.instance.application_name }
            seen_names << { expected: expected_name, actual: names.uniq }
          ensure
            Apartment::Tenant.switch!(Apartment.default_tenant)
          end
        end.each(&:join)

        2.times do
          result = seen_names.pop
          expect(result[:actual]).to eq([result[:expected]])
        end
      end

      # Every job includes ActiveJobTenant (config/initializers/apartment_activejob.rb),
      # whose perform_now wraps execution in Apartment::Tenant.switch(tenant) { super } -
      # which calls switch! (firing the :switch callback, i.e. Site.reset!) on entry AND
      # exit. This proves that mechanism actually protects sequential job execution on a
      # reused thread (the GoodJob/Sidekiq thread-pool-reuse scenario), using the real
      # job execution path rather than calling Apartment::Tenant.switch! directly.
      it 'does not leak a memoized Site across sequential job executions on the same thread' do
        old_job = SiteNameCapturingJob.new
        old_job.tenant = old_account.tenant
        new_job = SiteNameCapturingJob.new
        new_job.tenant = new_account.tenant

        expect(old_job.perform_now).to eq('old site')
        expect(new_job.perform_now).to eq('new site')
      end
    end
  end

  describe ".superadmin_emails" do
    subject { described_class.instance }

    context "no admins exist" do
      it "returns empty array" do
        expect(subject.superadmin_emails).to eq([])
      end
    end

    context "admins exist" do
      before do
        admin1.add_role :superadmin, subject
        admin2.add_role :superadmin, subject
      end

      it "returns array of emails" do
        expect(subject.superadmin_emails).to match_array([admin1.email, admin2.email])
      end
    end
  end

  describe ".admin_emails" do
    subject { described_class.instance }

    context "no admins exist" do
      it "returns empty array" do
        expect(subject.admin_emails).to eq([])
      end
    end

    context "admins exist" do
      before do
        admin1.add_role :admin, subject
        admin2.add_role :admin, subject
      end

      it "returns array of emails" do
        expect(subject.admin_emails).to match_array([admin1.email, admin2.email])
      end
    end
  end

  describe ".admin_emails=" do
    subject { described_class.instance }

    context "passed empty array" do
      before do
        admin1.add_role :admin, subject
        admin2.add_role :admin, subject
      end

      it "clears out all admins" do
        expect(subject.admin_emails).to match_array([admin1.email, admin2.email])
        subject.admin_emails = []
        expect(subject.admin_emails).to eq([])
      end
    end

    context "passed a new set of admins" do
      before do
        admin1.add_role :admin, subject
        admin2.add_role :admin, subject
      end

      it "overwrites existing admins with new set" do
        expect(subject.admin_emails).to match_array([admin1.email, admin2.email])
        subject.admin_emails = [admin3.email, admin1.email]
        expect(subject.admin_emails).to match_array([admin3.email, admin1.email])
      end
    end

    context "valid attributes" do
      subject { described_class.new }

      it "is valid without theme attributes" do
        expect(subject).to be_valid
      end

      it "is valid with home page theme attributes" do
        subject.home_theme = "Catchy Theme"
        subject.show_theme = "Images Show Page"
        subject.search_theme = "Grid View"
        expect(subject).to be_valid
        expect(subject.home_theme).to eq "Catchy Theme"
        expect(subject.show_theme).to eq "Images Show Page"
        expect(subject.search_theme).to eq "Grid View"
      end
    end
  end

  describe ".superadmin_emails=" do
    subject { described_class.instance }

    context "on a public demo tenant" do
      let(:account) { FactoryBot.create(:demo_account) }

      before do
        subject.update(account:)
        admin1.add_role :superadmin, subject
      end

      # The removal is refused outright rather than performed and reported, so
      # the role must survive a rejected assignment.
      it "keeps the superadmin and fails validation when passed an empty array" do
        subject.superadmin_emails = []

        expect(subject).not_to be_valid
        expect(subject.errors[:superadmin_emails])
          .to include(I18n.t('activerecord.errors.messages.cannot_remove_last_superadmin'))
        expect(subject.superadmin_emails).to eq([admin1.email])
      end

      it "keeps the superadmin and fails validation when passed only blank values" do
        subject.superadmin_emails = ['']

        expect(subject).not_to be_valid
        expect(subject.superadmin_emails).to eq([admin1.email])
      end

      it "keeps the superadmin and fails validation when the emails match no existing users" do
        subject.superadmin_emails = ['ghost@nowhere.org']

        expect(subject).not_to be_valid
        expect(subject.superadmin_emails).to eq([admin1.email])
      end

      it "does not block an assignment that keeps a superadmin" do
        subject.superadmin_emails = [admin1.email, admin2.email]

        expect(subject).to be_valid
      end

      it "allows swapping the last superadmin for another existing user in one assignment" do
        subject.superadmin_emails = [admin2.email]
        expect(subject.superadmin_emails).to eq([admin2.email])
      end

      it "allows removing one of several superadmins" do
        admin2.add_role :superadmin, subject
        subject.superadmin_emails = [admin1.email]
        expect(subject.superadmin_emails).to eq([admin1.email])
      end

      # The refusal describes the assignment just attempted. If it latched on,
      # correcting the mistake would still fail to save.
      it "stops reporting the refusal once a later assignment is acceptable" do
        subject.superadmin_emails = []
        expect(subject).not_to be_valid

        subject.superadmin_emails = [admin1.email, admin2.email]

        expect(subject).to be_valid
        expect(subject.errors[:superadmin_emails]).to be_empty
      end
    end

    context "on a standard tenant" do
      let(:account) { FactoryBot.create(:account) }

      before do
        subject.update(account:)
        admin1.add_role :superadmin, subject
      end

      it "clears out all superadmins when passed an empty array" do
        subject.superadmin_emails = []
        expect(subject.superadmin_emails).to eq([])
      end
    end

    context "when the site has no account" do
      before do
        admin1.add_role :superadmin, subject
      end

      it "clears out all superadmins when passed an empty array" do
        subject.superadmin_emails = []
        expect(subject.superadmin_emails).to eq([])
      end
    end
  end

  describe '#institution_label' do
    let(:site) { FactoryBot.create(:site) }

    before do
      allow(Site).to receive(:instance).and_return(site)
    end

    context 'when institution_name is present' do
      before do
        allow(site).to receive(:institution_name).and_return('My University')
      end

      it 'returns the custom institution label' do
        expect(site.institution_label).to eq 'My University'
      end
    end

    context 'when institution_name is not present' do
      let(:account) { instance_double("Account", cname: 'myuniversity.edu') }

      before do
        allow(site).to receive(:institution_name).and_return(nil)
        allow(site).to receive(:account).and_return(account)
      end

      it 'returns the cname of the associated account' do
        expect(site.institution_label).to eq 'myuniversity.edu'
      end
    end
  end

  describe '.reset!' do
    it 'drops the tenant-scoped caches and leaves keys it does not own' do
      RequestStore.store[:site_instance] = 'stale site'
      RequestStore.store[:content_blocks] = { 'block' => 'stale' }
      RequestStore.store[:qa_local_authorities] = { 'vocab' => 'stale' }
      RequestStore.store[:lograge_location] = '/keep/me'

      described_class.reset!

      expect(RequestStore.store.keys).to eq([:lograge_location])
    end
  end
end
