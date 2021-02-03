# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionSetService, clean: true do
  let(:user) { FactoryBot.create(:user) }
  let(:guest_user) { FactoryBot.create(:guest_user) }
  let(:permission_set) { PermissionSetService.new(user: user) }

  it 'can be initialized' do
    expect(permission_set).to be_an_instance_of(described_class)
  end

  context 'finding the user' do
    it 'can accept a user' do
      expect(permission_set.user).to eq(user)
    end

    it 'can accept a user id' do
      expect(permission_set.user).to eq(user)
    end

    context 'guest users' do
      let(:user) { guest_user }

      it 'can accept a guest user' do
        expect(permission_set.user).to eq(user)
      end

      it 'can accept a guest user id' do
        expect(permission_set.user).to eq(user)
      end
    end
  end

  context '#collection_manager?' do
    let(:role) { FactoryBot.create(:collection_manager_role) }

    context 'User has :collection_manager Role' do
      before do
        user.add_role(role.name)
      end

      it "infers Collection Manager status from the User's Roles" do
        expect(permission_set.collection_manager?).to eq(true)
      end
    end

    context 'User has a Hyrax::Group membership that includes the :collection_manager Role' do
      let(:hyrax_group) { FactoryBot.create(:group, name: 'Collection Management') }

      before do
        hyrax_group.roles << role
        hyrax_group.add_members_by_id(user.id)
      end

      it 'infers Collection Manager status from group memebership' do
        expect(permission_set.collection_manager?).to eq(true)
      end
    end

    context 'User does not have the collection_manager Role or any Hyrax::Group memberships' do
      it 'is not a Collection Manager' do
        expect(permission_set.collection_manager?).to eq(false)
      end
    end
  end
end
