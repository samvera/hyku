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
  end
end
