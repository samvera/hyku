# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupAwareRoleChecker, clean: true do
  let(:user) { FactoryBot.create(:user) }
  let(:guest_user) { FactoryBot.create(:guest_user) }
  let(:group_aware_role_checker) { GroupAwareRoleChecker.new(user: user) }

  it 'can be initialized' do
    expect(group_aware_role_checker).to be_an_instance_of(described_class)
  end

  context 'finding the user' do
    it 'can accept a user' do
      expect(group_aware_role_checker.user).to eq(user)
    end

    it 'can accept a user id' do
      expect(group_aware_role_checker.user).to eq(user)
    end

    context 'guest users' do
      let(:user) { guest_user }

      it 'can accept a guest user' do
        expect(group_aware_role_checker.user).to eq(user)
      end

      it 'can accept a guest user id' do
        expect(group_aware_role_checker.user).to eq(user)
      end
    end
  end

  context 'when User has the role' do
    before do
      user.add_role(role.name)
    end

    describe '#collection_manager?' do
      let(:role) { FactoryBot.create(:collection_manager_role) }

      it "infers Collection Manager status from the User's roles" do
        expect(group_aware_role_checker.collection_manager?).to eq(true)
      end
    end

    describe '#collection_editor?' do
      let(:role) { FactoryBot.create(:collection_editor_role) }

      it "infers Collection Editor status from the User's roles" do
        expect(group_aware_role_checker.collection_editor?).to eq(true)
      end
    end

    describe '#collection_reader?' do
      let(:role) { FactoryBot.create(:collection_reader_role) }

      it "infers Collection Reader status from the User's roles" do
        expect(group_aware_role_checker.collection_reader?).to eq(true)
      end
    end
  end

  context 'User has a Hyrax::Group membership that includes the role' do
    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
    end

    describe '#collection_manager?' do
      let(:role) { FactoryBot.create(:collection_manager_role) }
      let(:hyrax_group) { FactoryBot.create(:group, name: 'Collection Managers') }

      it "infers Collection Manager status from the group membership" do
        expect(group_aware_role_checker.collection_manager?).to eq(true)
      end
    end

    describe '#collection_editor?' do
      let(:role) { FactoryBot.create(:collection_editor_role) }
      let(:hyrax_group) { FactoryBot.create(:group, name: 'Collection Editors') }

      it "infers Collection Editor status from the group membership" do
        expect(group_aware_role_checker.collection_editor?).to eq(true)
      end
    end

    describe '#collection_reader?' do
      let(:role) { FactoryBot.create(:collection_reader_role) }
      let(:hyrax_group) { FactoryBot.create(:group, name: 'Collection Readers') }

      it "infers Collection Reader status from the group membership" do
        expect(group_aware_role_checker.collection_reader?).to eq(true)
      end
    end
  end
end
