# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'actions permitted by the collection_manager role', type: :feature, js: true, clean: true, ci: 'skip' do # rubocop:disable Layout/LineLength
  let(:role) { FactoryBot.create(:role, :collection_manager) }
  let(:collection) { FactoryBot.valkyrie_create(:hyku_collection, collection_type_gid:) }
  let(:collection_type_gid) { FactoryBot.create(:collection_type).to_global_id.to_s }
  let(:user) { FactoryBot.create(:user) }

  context 'a User that has the collection_manager role' do
    before do
      user.add_role(role.name, Site.instance)
      login_as user
    end

    it 'can create a Collection' do
      visit '/dashboard/collections/new'
      fill_in('Title', with: 'Collection Manager Test')
      fill_in('collection_creator', with: 'Somebody New and Special')
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
      fill_in('Title', with: 'New Collection Title')
      fill_in('collection_creator', with: 'Somebody New and Special')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L365-L384
    it 'can destroy an individual Collection from the Dashboard index view' do
      collection

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
      expect { CollectionResource.find(collection.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end

    it 'can destroy batches of Collections from the Dashboard index view' do
      collection
      visit '/dashboard/collections'

      within('#document_' + collection.id) do
        first('#batch_document_' + collection.id).click
      end

      find('#delete-collections-button').click

      within('.modal-content') do
        find('.submits-batches').click
      end

      expect(page).not_to have_content(collection.title.first)
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

      within('.set-access-controls') do
        expect(find('input#collection_visibility_restricted').checked?).to eq(true)
        expect(find('input#collection_visibility_open').checked?).to eq(false)
        expect(find('input#collection_visibility_authenticated').checked?).to eq(false)
      end

      find('input#collection_visibility_open').click
      click_button('Save changes')

      expect(page).to have_content('Collection was successfully updated.')
      expect(find('input#collection_visibility_open').checked?).to eq(true)
      expect(find('input#collection_visibility_restricted').checked?).to eq(false)
      expect(CollectionResource.find(collection.id).visibility).to eq('open')
    end

    # Tests custom :manage_items_in_collection ability
    # TODO: Skip this batch of tests since they consistently fails if we don't `sleep` for
    # an unacceptably long time in each one of them
    xdescribe 'managing subcollections' do
      it 'can add an existing collection as a subcolleciton' do
        sub_col = FactoryBot.create(:private_collection_lw, with_permission_template: true)
        expect(collection.member_collection_ids.count).to eq(0)

        visit "/dashboard/collections/#{collection.id}"
        click_button 'Add a subcollection'

        within("div#add-subcollection-modal-#{collection.id}") do
          select sub_col.title.first, from: 'child_id'
          click_button 'Add a subcollection'
        end
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        expect(page).to have_content("'#{sub_col.title.first}' has been added to '#{collection.title.first}'")
        expect(collection.reload.member_collection_ids.count).to eq(1)
      end

      it 'can create a new collection as a subcolleciton' do
        expect(collection.member_collection_ids.count).to eq(0)

        visit "/dashboard/collections/#{collection.id}"
        click_link 'Create new collection as subcollection'
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        fill_in('Title', with: 'CM-created subcollection')
        fill_in('collection_creator', with: 'Somebody New and Special')
        click_button 'Save'

        expect(page).to have_content('Collection was successfully created.')
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content('CM-created subcollection')
      end

      it "can remove a subcollection from the parent collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content(sub_col.title.first)
        find("li[data-id='#{sub_col.id}']").find('.remove-subcollection-button').click

        within('.delete-collection-form') do
          click_button 'Remove'
        end
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        expect(page).to have_content("'#{sub_col.title.first}' has been removed from '#{collection.title.first}'")
        expect(collection.member_collection_ids.count).to eq(0)
      end

      it "can remove a subcollection from the child collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{sub_col.id}"
        expect(page).to have_content(collection.title.first)
        find("li[data-parent-id='#{collection.id}']").find('.remove-from-collection-button').click

        within('.delete-collection-form') do
          click_button 'Remove'
        end
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        expect(page).to have_content("'#{sub_col.title.first}' has been removed from '#{collection.title.first}'")
        expect(collection.member_collection_ids.count).to eq(0)
      end
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing works' do
      it 'can add an existing work to a collection' do
        # Make current_user the depositor because the "Add existing works to this collection"
        # button navigates to the My Works index view
        work = FactoryBot.valkyrie_create(:generic_work_resource, visibility_setting: 'open', depositor: user.user_key)

        expect(collection.members_of.to_a).to be_empty

        visit "/dashboard/collections/#{collection.id}"
        click_link 'Add existing works to this collection'

        find("input#batch_document_#{work.id}").click
        click_button 'Add to collection'
        within('.modal-content') do
          click_button 'Save changes'
        end

        expect(page).to have_content('Collection was successfully updated.')
        expect(page).to have_content(work.title.first)
        expect(collection.members_of.to_a.map(&:id)).to match_array([work.id])
      end

      it 'cannot deposit a new work through a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Deposit new work through this collection')
      end

      it 'can remove a public work from a collection' do
        work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'authenticated')
        expect(collection.members_of.to_a).to eq([work])

        visit "/dashboard/collections/#{collection.id}"
        expect { find("tr#document_#{work.id}").find('.collection-remove.btn-danger').click }
          .to change { collection.members_of.to_a }.from([work]).to([])
        expect(page).to have_content('Collection was successfully updated.')
      end

      it 'can remove an institutional work from a collection' do
        work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'authenticated')

        visit "/dashboard/collections/#{collection.id}"
        expect { find("tr#document_#{work.id}").find('.collection-remove.btn-danger').click }
          .to change { collection.members_of.to_a }.from([work]).to([])
        expect(page).to have_content('Collection was successfully updated.')
      end

      it 'cannot see private works in a collection' do
        work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'restricted')
        expect(collection.members_of.to_a).to eq([work])

        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_selector("tr#document_#{work.id}")
        expect(page).to have_content(
          'The collection is either empty or does not contain items to which you have access.'
        )
      end
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
      fill_in('collection_creator', with: 'Somebody New and Special')
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
      fill_in('Title', with: 'New Collection Title')
      fill_in('collection_creator', with: 'Somebody New and Special')
      click_button 'Save'

      expect(page).to have_content('Collection was successfully updated.')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L365-L384
    it 'can destroy a Collection from the Dashboard index view' do
      collection
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

      # Yup it is gone
      expect { CollectionResource.find(collection.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError
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

      within('.set-access-controls') do
        expect(find('input#collection_visibility_restricted').checked?).to eq(true)
        expect(find('input#collection_visibility_open').checked?).to eq(false)
        expect(find('input#collection_visibility_authenticated').checked?).to eq(false)
      end

      find('input#collection_visibility_open').click
      click_button('Save changes')

      expect(page).to have_content('Collection was successfully updated.')

      expect(find('input#collection_visibility_open').checked?).to eq(true)
      expect(find('input#collection_visibility_restricted').checked?).to eq(false)
      expect(CollectionResource.find(collection.id).visibility).to eq('open')
    end

    # Tests custom :manage_items_in_collection ability
    # TODO: Skip this batch of tests since they consistently fails if we don't `sleep` for
    # an unacceptably long time in each one of them
    xdescribe 'managing subcollections' do
      it 'can add an existing collection as a subcolleciton' do
        sub_col = FactoryBot.create(:private_collection_lw, with_permission_template: true)
        expect(collection.member_collection_ids.count).to eq(0)

        visit "/dashboard/collections/#{collection.id}"
        click_button 'Add a subcollection'

        within("div#add-subcollection-modal-#{collection.id}") do
          select sub_col.title.first, from: 'child_id'
          click_button 'Add a subcollection'
        end
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        expect(page).to have_content("'#{sub_col.title.first}' has been added to '#{collection.title.first}'")
        expect(collection.reload.member_collection_ids.count).to eq(1)
      end

      it 'can create a new collection as a subcolleciton' do
        expect(collection.member_collection_ids.count).to eq(0)

        visit "/dashboard/collections/#{collection.id}"
        click_link 'Add new collection to this Collection'
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        fill_in('Title', with: 'CM-created subcollection')
        fill_in('collection_creator', with: 'Somebody New and Special')
        click_button 'Save'

        expect(page).to have_content('Collection was successfully created.')
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content('CM-created subcollection')
      end

      it "can remove a subcollection from the parent collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content(sub_col.title.first)
        find("li[data-id='#{sub_col.id}']").find('.remove-subcollection-button').click

        within('.delete-collection-form') do
          click_button 'Remove'
        end
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        expect(page).to have_content("'#{sub_col.title.first}' has been removed from '#{collection.title.first}'")
        expect(collection.member_collection_ids.count).to eq(0)
      end

      it "can remove a subcollection from the child collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{sub_col.id}"
        expect(page).to have_content(collection.title.first)
        find("li[data-parent-id='#{collection.id}']").find('.remove-from-collection-button').click

        within('.delete-collection-form') do
          click_button 'Remove'
        end
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10

        expect(page).to have_content("'#{sub_col.title.first}' has been removed from '#{collection.title.first}'")
        expect(collection.member_collection_ids.count).to eq(0)
      end
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing works' do
      it 'can add an existing work to a collection' do
        # Make current_user the depositor because the "Add existing works to this collection"
        # button navigates to the My Works index view
        work = FactoryBot.valkyrie_create(:generic_work_resource, depositor: user.user_key, visibility_setting: 'open')
        expect(collection.members_of.to_a).to eq([]) # Not in the collection yet...but it will be soon

        visit "/dashboard/collections/#{collection.id}"
        click_link 'Add existing works to this collection'

        find("input#batch_document_#{work.id}").click
        click_button 'Add to collection'
        within('.modal-content') do
          click_button 'Save changes'
        end

        expect(page).to have_content('Collection was successfully updated.')
        expect(page).to have_content(work.title.first)

        # Mapping IDs because I was getting a failure on comparison; which shouldn't be failing but
        # I don't have time nor space to figure that out.
        expect(collection.members_of.map(&:id)).to match_array([work.id])
      end

      it 'cannot deposit a new work through a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Deposit new work through this collection')
      end

      it 'can remove a public work from a collection' do
        # TODO: This requires more review as there might be a confirmation dialog that is
        # interfering.
        work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'open')
        expect(collection.members_of.to_a).to eq([work])

        visit "/dashboard/collections/#{collection.id}"
        find("tr#document_#{work.id}").find('.collection-remove.btn-danger').click
        expect(page).to have_content('Collection was successfully updated.')

        expect(collection.members_of.to_a).to eq([])
      end

      it 'can remove an institutional work from a collection' do
        # TODO: This requires more review as there might be a confirmation dialog that is
        # interfering.
        work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'authenticated')
        expect(collection.members_of.to_a).to eq([work])

        visit "/dashboard/collections/#{collection.id}"

        find("tr#document_#{work.id}").find('.collection-remove.btn-danger').click

        expect(page).to have_content('Collection was successfully updated.')

        expect(collection.members_of.to_a).to eq([])
      end

      it 'cannot see private works in a collection' do
        work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member, member_of_collection_ids: [collection.id], visibility_setting: 'restricted')
        expect(collection.members_of.to_a).to eq([work])

        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_selector("tr#document_#{work.id}")
        expect(page).to have_content(
          'The collection is either empty or does not contain items to which you have access.'
        )
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
