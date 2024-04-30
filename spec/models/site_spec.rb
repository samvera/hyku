# frozen_string_literal: true

RSpec.describe Site, type: :model do
  let(:admin1) { FactoryBot.create(:user, email: 'bob@was_here.net') }
  let(:admin2) { FactoryBot.create(:user, email: 'jane@was_here.net') }
  let(:admin3) { FactoryBot.create(:user, email: 'i@was_here.net') }

  describe ".instance" do
    context "on global tenant" do
      before do
        allow(Account).to receive(:global_tenant?).and_return true
      end

      it "is a NilSite" do
        expect(described_class.instance).to eq(NilSite.instance)
      end
    end

    context "on a specific tenant" do
      it "is a singleton site" do
        expect(described_class.instance).to eq(described_class.instance)
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
end
