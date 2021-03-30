# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'actions permitted by the collection_manager role', type: :feature, js: true, clean: true do
  let!(:role) { FactoryBot.create(:collection_manager_role) }
  let!(:collection) { FactoryBot.create(:private_collection_lw, with_permission_template: true) }
  let(:user) { FactoryBot.create(:user) }
  let(:group_aware_role_checker) { ::GroupAwareRoleChecker.new(user: user) }

  context 'a User that has the collection_manager role' do
    before do
      user.add_role(role.name, Site.instance)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Manager Test')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
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

    it 'can edit and update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      fill_in('Title', with: 'New Collection Title')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L365-L384
    it 'can destroy a Collection from the Dashboard index view' do
      visit '/dashboard/collections'

      within('table#collections-list-table') do
        expect(page).to have_content(collection.title.first)
      end
      check_tr_data_attributes(collection.id, 'collection')
      # check that modal data attributes haven't been added yet
      expect(page).not_to have_selector("div[data-id='#{collection.id}']")

      within('#document_' + collection.id) do
        first('button.dropdown-toggle').click
        first('.itemtrash').click
      end
      expect(page).to have_selector('div#collection-empty-to-delete-modal', visible: true)
      check_modal_data_attributes(collection.id, 'collection')

      within('div#collection-empty-to-delete-modal') do
        click_button('Delete')
      end
      expect(page).to have_current_path('/dashboard/my/collections?locale=en')

      visit '/dashboard/collections'

      within('table#collections-list-table') do
        expect(page).not_to have_content(collection.title.first)
      end
    end

    it 'can destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      accept_confirm { click_link_or_button('Delete collection') }

      expect(page).to have_content('Collection was successfully deleted')
    end

    # Tests custom :manage_discovery ability
    it 'can change the visibility (discovery) of a Collection' do
      expect(collection.visibility).to eq('restricted')

      visit "dashboard/collections/#{collection.id}/edit"
      click_link('Discovery')
      expect(find('input#visibility_restricted').checked?).to eq(true)
      expect(find('div.form-group')['title']).to be_blank
      find('div.form-group').all(:css, 'input[id^=visibility]').each do |input|
        expect(input.disabled?).to eq(false)
      end

      find('input#visibility_open').click
      click_button('Save changes')

      expect(page).to have_content('Collection was successfully updated.')
      expect(find('input#visibility_open').checked?).to eq(true)
      expect(find('input#visibility_restricted').checked?).to eq(false)
      expect(collection.reload.visibility).to eq('open')
    end
  end

  context 'a User in a Hyrax::Group that has the collection_manager role' do
    let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_management_group') }

    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Manager Test')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
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

    it 'can edit and update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      fill_in('Title', with: 'New Collection Title')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L365-L384
    it 'can destroy a Collection from the Dashboard index view' do
      visit '/dashboard/collections'

      within('table#collections-list-table') do
        expect(page).to have_content(collection.title.first)
      end
      check_tr_data_attributes(collection.id, 'collection')
      # check that modal data attributes haven't been added yet
      expect(page).not_to have_selector("div[data-id='#{collection.id}']")

      within('#document_' + collection.id) do
        first('button.dropdown-toggle').click
        first('.itemtrash').click
      end
      expect(page).to have_selector('div#collection-empty-to-delete-modal', visible: true)
      check_modal_data_attributes(collection.id, 'collection')

      within('div#collection-empty-to-delete-modal') do
        click_button('Delete')
      end
      expect(page).to have_current_path('/dashboard/my/collections?locale=en')

      visit '/dashboard/collections'

      within('table#collections-list-table') do
        expect(page).not_to have_content(collection.title.first)
      end
    end

    it 'can destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      accept_confirm { click_link_or_button('Delete collection') }

      expect(page).to have_content('Collection was successfully deleted')
    end

    # Tests custom :manage_discovery ability
    it 'can change the visibility (discovery) of a Collection' do
      expect(collection.visibility).to eq('restricted')

      visit "dashboard/collections/#{collection.id}/edit"
      click_link('Discovery')
      expect(find('input#visibility_restricted').checked?).to eq(true)
      expect(find('div.form-group')['title']).to be_blank
      find('div.form-group').all(:css, 'input[id^=visibility]').each do |input|
        expect(input.disabled?).to eq(false)
      end

      find('input#visibility_open').click
      click_button('Save changes')

      expect(page).to have_content('Collection was successfully updated.')
      expect(find('input#visibility_open').checked?).to eq(true)
      expect(find('input#visibility_restricted').checked?).to eq(false)
      expect(collection.reload.visibility).to eq('open')
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
