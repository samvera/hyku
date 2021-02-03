# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'collection_manager role', type: :feature, js: true, clean: true do
  let!(:role) { FactoryBot.create(:collection_manager_role) }
  let(:user) { FactoryBot.create(:user) }
  let(:permission_set) { ::PermissionSetService.new(user: user) }

  before do
    Hyrax::CollectionType.find_or_create_default_collection_type
  end

  context 'a User that has the collection_manager role' do
    before do
      user.add_role(role.name)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new?collection_type_id=1'
      fill_in('Title', with: 'Collection Manager Test')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
    end
  end

  context 'a User in a Hyrax::Group that has the collection_manager role' do
    let(:hyrax_group) { FactoryBot.create(:group, name: 'Collection Management Group') }

    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new?collection_type_id=1'
      fill_in('Title', with: 'Collection Manager Test')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
    end
  end
end
