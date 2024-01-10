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

  describe 'an ordinary user with a role on this tenant' do
    let(:user) do
      u = FactoryBot.create(:user)
      u.add_role(:depositor)
      u
    end

    it { is_expected.not_to be_able_to(:manage, :all) }
    it { is_expected.not_to be_able_to(:manage, Account) }
    it { is_expected.not_to be_able_to(:manage, Site) }

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
  end

  describe 'a superadmin user' do
    let(:user) { FactoryBot.create(:superadmin) }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  describe 'a user_manager user' do
    let(:user) { FactoryBot.create(:user) }
    let(:ordinary_role) { FactoryBot.create(:role, name: 'ordinary_role') }

    before do
      user.add_role :user_manager, Site.instance
    end

    context 'when managing User and Role' do
      it 'can create, read, update, and edit User and Role' do
        expect(ability).to be_able_to(:create, User.new)
        expect(ability).to be_able_to(:read, User.new)
        expect(ability).to be_able_to(:update, User.new)
        expect(ability).to be_able_to(:edit, User.new)
      end
    end
  end

  # Brought over from blacklight-access_controls v0.6.2
  describe '#user_groups' do
    subject { ability.user_groups }

    context 'an admin user' do
      let(:user) { FactoryBot.create(:admin) }

      it { is_expected.to contain_exactly('admin', 'registered', 'public') }
    end

    # NOTE(bkiahstroud): Override to test guest users instead of
    # "unregistered" (User.new) users; see User#add_default_group_membership!
    context 'a guest user' do
      let(:user) { create(:guest_user) }

      it { is_expected.to contain_exactly('public') }
    end

    context 'a registered user' do
      let(:user) { create(:user) }

      it { is_expected.to contain_exactly('registered', 'public') }
    end

    # NOTE(bkiahstroud): Override test to create Hyrax::Groups
    # that the user is a member of.
    context 'a user with groups' do
      let(:user)    { create(:user) }

      before do
        create(:group, name: 'group1', member_users: [user])
        create(:group, name: 'group2', member_users: [user])
      end

      it { is_expected.to include('group1', 'group2') }
    end
  end

  describe '#admin?' do
    subject { ability.admin? }

    context 'a user with the admin role' do
      let(:user) { create(:admin) }

      it { is_expected.to eq(true) }
    end

    context 'a user in the admin Hyrax::Group' do
      let(:user) { create(:user) }

      before do
        create(:admin_group, member_users: [user])
      end

      it { is_expected.to eq(true) }
    end

    context 'a user without the admin role' do
      let(:user) { create(:user) }

      it { is_expected.to eq(false) }
    end

    context 'a user not in the admin Hyrax::Group' do
      let(:user) { create(:user) }

      before do
        create(:group, name: 'non-admin', member_users: [user])
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#all_user_and_group_roles' do
    let(:user) { create(:user) }
    let(:user_reader_role) { create(:role, :user_reader) }
    let(:collection_editor_role) { create(:role, :collection_editor) }
    let(:work_depositor_role) { create(:role, :work_depositor) }

    before do
      user.add_role(user_reader_role.name, Site.instance)
      create(
        :group,
        name: 'test_group',
        member_users: [user],
        roles: [collection_editor_role.name, work_depositor_role.name]
      )
    end

    it 'lists all role names that apply to the user' do
      expect(subject.all_user_and_group_roles).to contain_exactly(
        user_reader_role.name,
        collection_editor_role.name,
        work_depositor_role.name
      )
    end
  end
end
