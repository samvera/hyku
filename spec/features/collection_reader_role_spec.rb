# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'actions permitted by the collection_reader role', type: :feature, js: true, clean: true do
  let!(:role) { FactoryBot.create(:collection_reader_role) }
  let!(:collection) { FactoryBot.create(:private_collection_lw, with_permission_template: true) }
  let(:user) { FactoryBot.create(:user) }
  let(:group_aware_role_checker) { ::GroupAwareRoleChecker.new(user: user) }

  context 'a User that has the collection_reader role' do
    before do
      user.add_role(role.name)
      login_as user
    end

    # TODO: This fails due to :everyone_can_create_curation_concerns being included in
    # Ability.ability_logic. Unskip after :everyone_can_create_curation_concerns
    # is removed from ability logic (Work roles must be completed first)
    xit 'cannot create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Reader Test')
      expect { click_button 'Save' }.not_to change(Collection, :count)

      expect(page).not_to have_content('Collection was successfully created.')
    end

    it 'can view all Collections' do
      visit '/dashboard/collections'
      expect(find('table#collections-list-table'))
        .to have_selector(:id, "document_#{collection.id}")
    end

    it 'can view an individual Collection' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot edit or update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(page).to have_content('You do not have sufficient privileges to edit this document')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L463-L476
    it 'cannot destroy a Collection from the Dashboard index view' do
      visit '/dashboard/collections'

      expect(page).to have_content(collection.title.first)
      check_tr_data_attributes(collection.id, 'collection')
      within("#document_#{collection.id}") do
        first('button.dropdown-toggle').click
        first('.itemtrash').click
      end

      # Exepct the modal to be shown that explains why the user can't delete the collection.
      expect(page).to have_selector('div#collection-to-delete-deny-modal', visible: true)
      within('div#collection-to-delete-deny-modal') do
        click_button('Close')
      end
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).not_to have_content('Delete collection')
    end
  end

  context 'a User in a Hyrax::Group that has the collection_reader role' do
    let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_reader_group') }

    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
      login_as user
    end

    # TODO: This fails due to :everyone_can_create_curation_concerns being included in
    # Ability.ability_logic. Unskip after :everyone_can_create_curation_concerns
    # is removed from ability logic (Work roles must be completed first)
    xit 'cannot create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Reader Test')
      expect { click_button 'Save' }.not_to change(Collection, :count)

      expect(page).not_to have_content('Collection was successfully created.')
    end

    it 'can view all Collections' do
      visit '/dashboard/collections'
      expect(find('table#collections-list-table'))
        .to have_selector(:id, "document_#{collection.id}")
    end

    it 'can view an individual Collection' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot edit or update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(page).to have_content('You do not have sufficient privileges to edit this document')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L463-L476
    it 'cannot destroy a Collection from the Dashboard index view' do
      visit '/dashboard/collections'

      expect(page).to have_content(collection.title.first)
      check_tr_data_attributes(collection.id, 'collection')
      within("#document_#{collection.id}") do
        first('button.dropdown-toggle').click
        first('.itemtrash').click
      end

      # Exepct the modal to be shown that explains why the user can't delete the collection.
      expect(page).to have_selector('div#collection-to-delete-deny-modal', visible: true)
      within('div#collection-to-delete-deny-modal') do
        click_button('Close')
      end
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).not_to have_content('Delete collection')
    end
  end

  # NOTE: Helper methods from Hyrax v2.9.0 spec/features/dashboard/collection_spec.rb

  # check table row has appropriate data attributes added
  def check_tr_data_attributes(id, type)
    url_fragment = get_url_fragment(type)
    expect(page).to have_selector("tr[data-id='#{id}'][data-colls-hash]")
    expect(page).to have_selector("tr[data-post-url='/dashboard/collections/#{id}/within?locale=en']")
    expect(page).to have_selector("tr[data-post-delete-url='/#{url_fragment}/#{id}?locale=en']")
  end

  # check data attributes have been transferred from table row to the modal
  def check_modal_data_attributes(id, type)
    url_fragment = get_url_fragment(type)
    expect(page).to have_selector("div[data-id='#{id}']")
    expect(page).to have_selector("div[data-post-delete-url='/#{url_fragment}/#{id}?locale=en']")
  end

  def get_url_fragment(type)
    (type == 'admin_set' ? 'admin/admin_sets' : 'dashboard/collections')
  end
end
