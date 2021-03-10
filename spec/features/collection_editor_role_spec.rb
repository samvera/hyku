# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'actions permitted by the collection_editor role', type: :feature, js: true, clean: true do
  let!(:role) { FactoryBot.create(:collection_editor_role) }
  let(:user) { FactoryBot.create(:user) }
  let(:group_aware_role_checker) { ::GroupAwareRoleChecker.new(user: user) }

  context 'a User that has the collection_editor role' do
    before do
      user.add_role(role.name)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Editor Test')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
    end

    it 'can edit and update a Collection' do
      collection = FactoryBot.create(:collection_lw, with_permission_template: true)

      visit "/dashboard/collections/#{collection.id}/edit"
      fill_in('Title', with: 'New Collection Title')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end
  end

  context 'a User in a Hyrax::Group that has the collection_editor role' do
    let(:hyrax_group) { FactoryBot.create(:group, name: 'Collection Editor Group') }

    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Editor Test')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
    end

    # TODO: unskip when the GroupAwareRoleChecker is hooked up to the Ability model
    xit 'can edit and update a Collection' do
      collection = FactoryBot.create(:collection_lw, with_permission_template: true)

      visit "/dashboard/collections/#{collection.id}/edit"
      fill_in('Title', with: 'New Collection Title')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end
  end
end
