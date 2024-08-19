# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'actions permitted by the collection_editor role', type: :feature, js: true, clean: true, ci: 'skip' do # rubocop:disable Layout/LineLength
  let(:role) { FactoryBot.create(:role, :collection_editor) }
  let(:collection) { FactoryBot.valkyrie_create(:hyku_collection, collection_type_gid:) }
  let(:collection_type_gid) { create(:collection_type).to_global_id.to_s }
  let(:user) { FactoryBot.create(:user) }

  context 'a User that has the collection_editor role' do
    before do
      user.add_role(role.name, Site.instance)
      login_as user
    end

    it 'has the proper abilities' do
      # This spec is a canary in a coal mine, if it fails it likely means the other specs are going
      # to fail.
      ability = Ability.new(user)
      collection
      expect(ability.can?(:create, Hyrax.config.collection_class)).to be_truthy
      expect(ability.can?(:show, collection)).to be_truthy
      expect(ability.can?(:show, collection.id)).to be_truthy
      expect(ability.can?(:edit, collection)).to be_truthy
      expect(ability.can?(:edit, collection.id)).to be_truthy
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      # Ensure that you are filling out all of the required attributes
      fill_in('collection_title', with: 'Collection Editor Test')
      fill_in('collection_creator', with: 'Someone special')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
    end

    it 'can view all Collections and the individual collection' do
      collection
      visit '/dashboard/collections'

      expect(find('table#collections-list-table'))
        .to have_selector(:id, "document_#{collection.id}")

      visit "/dashboard/collections/#{collection.id}"
      expect(page).to have_content(collection.title.first)
    end

    it 'can edit and update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      fill_in('collection_title', with: 'Collection Editor Test')
      fill_in('collection_creator', with: 'Someone special')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L463-L476
    it 'cannot destroy an individual Collection from the Dashboard index view' do
      collection
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

    it 'cannot destroy batches of Collections from the Dashboard index view' do
      collection
      visit '/dashboard/collections'

      expect(find('tr#document_' + collection.id).first('input[type=checkbox]'))
        .to be_disabled
    end

    it 'cannot destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).not_to have_content('Delete collection')
    end

    # Tests custom :manage_discovery ability
    it 'cannot change the visibility (discovery) of a Collection' do
      expect(collection.visibility).to eq('restricted')

      visit "dashboard/collections/#{collection.id}/edit"
      click_link('Discovery')

      within('.set-access-controls') do
        expect(find('input#collection_visibility_restricted').checked?).to eq(true)
        expect(find('input#collection_visibility_open').checked?).to eq(false)
        expect(find('input#collection_visibility_authenticated').checked?).to eq(false)
      end

      expect(find('.set-access-controls').text)
        .to include("You do not have permission to change this Collection's discovery setting")

      nodes = find('.set-access-controls').all(:css, 'input[name="collection[visibility]"]')
      expect(nodes.size).to eq(3) # restricted, open, authenticated
      nodes.each { |input| expect(input.disabled?).to eq(true) }
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing subcollections' do
      it 'cannot add an existing collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add a subcollection')
      end

      it 'cannot create a new collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add new collection to this Collection')
      end

      it "cannot remove a subcollection from the parent collection's show page" do
        sub_col = FactoryBot.valkyrie_create(
          :hyku_collection,
          :as_collection_member,
          with_permission_template: true,
          member_of_collection_ids: [collection.id.to_s]
        )
        expect(collection.member_collection_ids).to match_array([sub_col.id])

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content(sub_col.title.first)
        expect(find("li[data-id='#{sub_col.id}']")).not_to have_content('Remove')
      end

      it "cannot remove a subcollection from the child collection's show page" do
        sub_col = FactoryBot.valkyrie_create(
          :hyku_collection,
          :as_collection_member,
          with_permission_template: true,
          member_of_collection_ids: [collection.id.to_s]
        )
        expect(collection.member_collection_ids).to match_array([sub_col.id])

        visit "/dashboard/collections/#{sub_col.id}"
        expect(page).to have_content(collection.title.first)
        find("li[data-parent-id='#{collection.id}']").find('a[title="Remove"]').click

        expect(find('.delete-collection-form'))
          .to have_content('You do not have sufficient privileges for the parent collection to be able to remove it.')
        expect(find('.delete-collection-form')).not_to have_content('Remove')

        within('.delete-collection-form') do
          click_button 'Close'
        end

        expect(collection.member_collection_ids).to match_array([sub_col.id])
      end
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing works' do
      it 'cannot add an existing work to a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add existing works to this collection')
      end

      it 'cannot deposit a new work through a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Deposit new work through this collection')
      end

      it 'cannot remove any works from a collection' do
        public_work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'open')
        institutional_work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'authenticated')
        private_work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'restricted')

        expect(collection.member_collection_ids).to contain_exactly(public_work.id, institutional_work.id, private_work.id)

        visit "/dashboard/collections/#{collection.id}"

        expect(page).to have_selector("tr#document_#{public_work.id}"), "able to read public_work"
        expect(page).to have_selector("tr#document_#{institutional_work.id}"), "able to read institutional_work"
        expect(page).not_to have_selector("tr#document_#{private_work.id}"), "unable to read private_work"
        expect(find("tr#document_#{public_work.id}")).not_to have_content('Remove')
        expect(find("tr#document_#{institutional_work.id}")).not_to have_content('Remove')
      end
    end
  end

  context 'a User in a Hyrax::Group that has the collection_editor role' do
    let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_editor_group') }

    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('collection_title', with: 'Collection Editor Test')
      fill_in('collection_creator', with: 'Special Person')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully created.')
    end

    it 'can view all Collections' do
      collection
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
      fill_in('collection_title', with: 'New Collection Title')
      fill_in('collection_creator', with: 'Somebody made this')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L463-L476
    it 'cannot destroy a Collection from the Dashboard index view' do
      collection
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

    # Tests custom :manage_discovery ability
    it 'cannot change the visibility (discovery) of a Collection' do
      expect(collection.visibility).to eq('restricted')

      visit "dashboard/collections/#{collection.id}/edit"
      click_link('Discovery')
      within('.set-access-controls') do
        expect(find('input#collection_visibility_restricted').checked?).to eq(true)
        expect(find('input#collection_visibility_open').checked?).to eq(false)
        expect(find('input#collection_visibility_authenticated').checked?).to eq(false)
      end

      expect(find('.set-access-controls').text)
        .to include("You do not have permission to change this Collection's discovery setting")

      nodes = find('.set-access-controls').all(:css, 'input[name="collection[visibility]"]')
      expect(nodes.size).to eq(3) # restricted, open, authenticated
      nodes.each { |input| expect(input.disabled?).to eq(true) }
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing subcollections' do
      it 'cannot add an existing collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add a subcollection')
      end

      it 'cannot create a new collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add new collection to this Collection')
      end

      it "cannot remove a subcollection from the parent collection's show page" do
        sub_col = FactoryBot.valkyrie_create(
          :hyku_collection,
          :as_collection_member,
          with_permission_template: true,
          member_of_collection_ids: [collection.id.to_s]
        )

        expect(collection.member_collection_ids).to match_array([sub_col.id])

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content(sub_col.title.first)

        expect(find("li[data-id='#{sub_col.id}']")).not_to have_content('Remove')
      end

      it "cannot remove a subcollection from the child collection's show page" do
        sub_col = FactoryBot.valkyrie_create(
          :hyku_collection,
          :as_collection_member,
          with_permission_template: true,
          member_of_collection_ids: [collection.id.to_s]
        )

        expect(collection.members_of).to include(sub_col)

        visit "/dashboard/collections/#{sub_col.id}"
        expect(page).to have_content(collection.title.first)
        find("li[data-parent-id='#{collection.id}']").find('a[title="Remove"]').click

        expect(find('.delete-collection-form'))
          .to have_content('You do not have sufficient privileges for the parent collection to be able to remove it.')
        expect(find('.delete-collection-form')).not_to have_content('Remove')

        within('.delete-collection-form') do
          click_button 'Close'
        end

        # You cannot remove this
        expect(collection.member_collection_ids).to match_array([sub_col.id])
      end
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing works' do
      it 'cannot add an existing work to a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add existing works to this collection')
      end

      it 'cannot deposit a new work through a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Deposit new work through this collection')
      end

      it 'cannot remove any works from a collection' do
        public_work, institutional_work, private_work = ['open', 'authenticated', 'restricted'].map do |visibility_setting|
          FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting:)
        end

        expect(collection.members_of).to match_array([public_work, institutional_work, private_work])

        visit "/dashboard/collections/#{collection.id}"
        expect(find("tr#document_#{public_work.id}")).not_to have_content('Remove')
        expect(find("tr#document_#{institutional_work.id}")).not_to have_content('Remove')
        expect(page).not_to have_selector("tr#document_#{private_work.id}")
      end
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
