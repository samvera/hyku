# frozen_string_literal: true

require 'cancan/matchers'

RSpec.describe Ability do
  subject { ability }

  let(:ability) { described_class.new(user) }

  describe 'an anonymous user' do
    let(:user) { nil }

    it { is_expected.not_to be_able_to(:manage, :all) }
  end

  describe 'an ordinary user' do
    let(:user) { FactoryBot.create(:user) }

    it { is_expected.not_to be_able_to(:manage, :all) }

    describe "#user_groups" do
      subject { ability.user_groups }

      it "does have the registered group as they are created on this tenant" do
        expect(subject).to include 'registered'
      end

      it "does not have the admin group" do
        expect(subject).not_to include 'admin'
      end
    end
  end

  describe 'an ordinary user with a role on this tenant' do
    let(:user) do
      u = FactoryBot.create(:user)
      u.add_role(:depositor)
      u
    end

    it { is_expected.not_to be_able_to(:manage, :all) }

    describe "#user_groups" do
      subject { ability.user_groups }

      it "does have the registered group" do
        expect(subject).to include 'registered'
      end

      it "does not have the admin group" do
        expect(subject).not_to include 'admin'
      end
    end
  end

  describe 'an administrative user' do
    let(:user) { FactoryBot.create(:admin) }

    it { is_expected.not_to be_able_to(:manage, :all) }
    it { is_expected.not_to be_able_to(:manage, Account) }
    it { is_expected.to be_able_to(:manage, Site) }

    describe "#user_groups" do
      subject { ability.user_groups }

      it "has the admin group" do
        expect(subject).to include 'admin'
      end
    end
  end

  describe 'a superadmin user' do
    let(:user) { FactoryBot.create(:superadmin) }

    it { is_expected.to be_able_to(:manage, :all) }
  end
end
