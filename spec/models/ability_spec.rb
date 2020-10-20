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

  # Brought over from blacklight-access_controls v0.6.2
  describe '#user_groups' do
    subject { ability.user_groups }

    context 'an admin user' do
      let(:user) { FactoryBot.create(:admin) }

      it { is_expected.to contain_exactly('admin', 'registered', 'public') }
    end

    # NOTE(bkiahstroud): Override to test guest users instead of
    # "unregistered" (User.new) users; see User#add_default_group_memberships!
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
      let!(:group1) { create(:group, name: 'group1', member_users: [user]) }
      let!(:group2) { create(:group, name: 'group2', member_users: [user]) }

      it { is_expected.to include('group1', 'group2') }
    end
  end
end
