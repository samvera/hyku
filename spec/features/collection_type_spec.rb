# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Add Groups with Roles feature test coverage
# - Set :js to true because some specs require it
# - Changed #sign_in to #login_as (#sign_in was throwing undefined method errors)
# Other overrides are marked with an OVERRIDE comment
RSpec.describe 'collection_type', type: :feature, js: true, clean: true do
  let(:admin_user) { create(:admin) }
  let(:exhibit_title) { 'Exhibit' }
  let(:exhibit_description) { 'Description for exhibit collection type.' }
  let(:exhibit_collection_type) do
    create(
      :collection_type,
      title: exhibit_title,
      description: exhibit_description,
      creator_user: admin_user
    )
  end
  let(:user_collection_type) { create(:user_collection_type) }
  let(:admin_set_type) { create(:admin_set_collection_type) }
  let(:solr_gid) { Collection.collection_type_gid_document_field_name }

  describe 'index' do
    before do
      exhibit_collection_type
      user_collection_type
      admin_set_type
      login_as admin_user
      visit '/admin/collection_types'
    end

    # NOTE(bkiahstroud): set :js to false because the page can't see the modal Delete button if it's true
    it 'has page title and lists collection types', js: false do
      expect(page).to have_content 'Collection Types'
      expect(page).to have_content 'Admin Set'
      expect(page).to have_content 'User Collection'
      expect(page).to have_content 'Collection Type'

      expect(page).to have_link('Edit', count: 3)
      expect(page).to have_link('Edit', href: hyrax.edit_admin_collection_type_path(admin_set_type.id, locale: 'en'))
      expect(page).to have_link(
        'Edit',
        href: hyrax.edit_admin_collection_type_path(user_collection_type.id, locale: 'en')
      )
      expect(page).to have_link(
        'Edit',
        href: hyrax.edit_admin_collection_type_path(exhibit_collection_type.id, locale: 'en')
      )
      expect(page).to have_button('Delete', count: 2) # 1: Collection Type, 2: delete modal
    end
  end

  describe 'create collection type' do
    let(:title) { 'Test Type' }
    let(:description) { 'Description for collection type we are testing.' }

    before do
      login_as admin_user
      visit '/admin/collection_types'
    end

    it 'makes a new collection type', :js do
      click_link 'Create new collection type'

      expect(page).to have_content 'Create New Collection Type'

      # confirm only Description tab is visible
      expect(page).to have_link('Description', href: '#metadata')
      expect(page).not_to have_link('Settings', href: '#settings')
      expect(page).not_to have_link('Participants', href: '#participants')

      # confirm metadata fields exist
      expect(page).to have_selector 'input#collection_type_title'
      expect(page).to have_selector 'textarea#collection_type_description'

      # set values and save
      fill_in('Type name', with: title)
      fill_in('Type description', with: description)

      click_button('Save')

      # confirm values were set
      expect(page).to have_selector "input#collection_type_title[value='#{title}']"
      expect(page).to have_selector 'textarea#collection_type_description', text: description

      # confirm all edit tabs are now visible
      expect(page).to have_link('Description', href: '#metadata')
      expect(page).to have_link('Settings', href: '#settings')
      expect(page).to have_link('Participants', href: '#participants')
    end

    # rubocop:disable RSpec/ExampleLength
    it 'tries to make a collection type with existing title, and receives error message', :js do
      click_link 'Create new collection type'

      expect(page).to have_content 'Create New Collection Type'

      # confirm only Description tab is visible
      expect(page).to have_link('Description', href: '#metadata')
      expect(page).not_to have_link('Settings', href: '#settings')
      expect(page).not_to have_link('Participants', href: '#participants')

      # confirm metadata fields exist
      expect(page).to have_selector 'input#collection_type_title'
      expect(page).to have_selector 'textarea#collection_type_description'

      # set values and save
      fill_in('Type name', with: title)
      fill_in('Type description', with: description)

      click_button('Save')

      visit '/admin/collection_types'
      click_link 'Create new collection type'

      expect(page).to have_content 'Create New Collection Type'

      # confirm only Description tab is visible
      expect(page).to have_link('Description', href: '#metadata')
      expect(page).not_to have_link('Settings', href: '#settings')
      expect(page).not_to have_link('Participants', href: '#participants')

      # confirm metadata fields exist
      expect(page).to have_selector 'input#collection_type_title'
      expect(page).to have_selector 'textarea#collection_type_description'

      # set values and save
      fill_in('Type name', with: title)
      fill_in('Type description', with: description)

      click_button('Save')

      # Confirm error message is displayed.
      expect(page).to have_content 'Save was not successful because title has already been taken, ' \
                                   'and machine_id has already been taken.'
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe 'edit collection type' do
    context 'adding participants' do
      let!(:group) { FactoryBot.create(:group, name: 'dummy') }

      before do
        login_as admin_user
        visit "/admin/collection_types/#{user_collection_type.id}/edit#participants"
      end

      it 'displays the groups humanized name' do
        expect(page).to have_content 'Add Participants'
        expect(
          page.has_select?(
            'collection_type_participant_agent_id',
            with_options: [group.humanized_name]
          )
        ).to be true
      end
    end

    context 'when removing a group participant' do
      before do
        FactoryBot.create(:admin_group)

        login_as admin_user
        visit "/admin/collection_types/#{user_collection_type.id}/edit#participants"
      end

      it 'displays the agent_type in title case' do
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="admin"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td>Group</td>')
      end

      it 'shows a disabled remove button next to Repository Administrator group as a Manager' do
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="admin"]', match: :first)
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td data-agent="admin">Repository Administrators</td>')
        expect(manager_row_html).to include('<a class="btn btn-sm btn-danger disabled" disabled="disabled"')
      end

      it 'shows an enabled remove button next to Repository Administrator group as a Creator' do
        # select the Repository Administrators, assign role 'Creator', and add it to the collection type
        select("Repository Administrators", from: 'collection_type_participant_agent_id')
        select("Creator", from: 'collection_type_participant_access', match: :first)
        within('.section-participants') do
          click_button('Add', match: :first)
        end

        # wait one second for the item to populate in the table and check for it's existence
        sleep 1
        expect(page).to have_content("Participants Updated")
        creator_row_html = find('table.creators-table')
                           .find(:xpath, './/td[@data-agent="admin"]')
                           .find(:xpath, '..')['innerHTML']
        expect(creator_row_html).to include('<td data-agent="admin">Repository Administrators</td>')
        expect(creator_row_html).not_to include('<a class="btn btn-sm btn-danger disabled" disabled="disabled"')
      end
    end

    context 'when there are no collections of this type' do
      let(:title_old) { exhibit_title }
      let(:description_old) { exhibit_description }
      let(:title_new) { 'Exhibit modified' }
      let(:description_new) { 'Change in description for exhibit collection type.' }

      before do
        exhibit_collection_type
        login_as admin_user
        visit "/admin/collection_types/#{exhibit_collection_type.id}/edit"
      end

      it 'modifies metadata values of a collection type', :js do # rubocop:disable RSpec/ExampleLength
        expect(page).to have_content "Edit Collection Type: #{title_old}"

        # confirm all tabs are visible
        expect(page).to have_link('Description', href: '#metadata')
        expect(page).to have_link('Settings', href: '#settings')
        expect(page).to have_link('Participants', href: '#participants')

        # confirm metadata fields have original values
        expect(page).to have_selector "input#collection_type_title[value='#{title_old}']"
        expect(page).to have_selector 'textarea#collection_type_description', text: description_old

        # set values and save
        fill_in('Type name', with: title_new)
        fill_in('Type description', with: description_new)

        click_button('Save changes')

        expect(page).to have_content "Edit Collection Type: #{title_new}"

        # confirm values were set
        expect(page).to have_selector "input#collection_type_title[value='#{title_new}']"
        expect(page).to have_selector 'textarea#collection_type_description', text: description_new

        click_link('Settings', href: '#settings')

        # confirm all non-admin_set checkboxes are on
        expect(page).to have_checked_field('collection_type_nestable')
        expect(page).to have_checked_field('collection_type_brandable')
        expect(page).to have_checked_field('collection_type_discoverable')
        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_checked_field('collection_type_share_applies_to_new_works')
        expect(page).to have_checked_field('collection_type_allow_multiple_membership')

        # confirm all admin_set only checkboxes are off and disabled
        expect(page).to have_unchecked_field('collection_type_require_membership', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_visibility', disabled: true)

        # change settings
        page.uncheck('NESTING')
        page.uncheck('DISCOVERY')
        page.check('APPLY TO NEW WORKS')
        page.uncheck('MULTIPLE MEMBERSHIP')

        # confirm all non-admin_set checkboxes are now off
        expect(page).to have_unchecked_field('collection_type_nestable')
        expect(page).to have_checked_field('collection_type_brandable')
        expect(page).to have_unchecked_field('collection_type_discoverable')
        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_checked_field('collection_type_share_applies_to_new_works')
        expect(page).to have_unchecked_field('collection_type_allow_multiple_membership')

        # uncheck sharable should disable sharable options
        page.uncheck('SHARING')

        expect(page).to have_unchecked_field('collection_type_sharable')
        expect(page).to have_unchecked_field('collection_type_share_applies_to_new_works', disabled: true)

        # check sharable should enable sharable options
        page.check('SHARING')

        expect(page).to have_checked_field('collection_type_sharable')
        expect(page).to have_unchecked_field('collection_type_share_applies_to_new_works', disabled: false)

        click_link('Participants')

        # TODO: Test adding participants
      end

      context 'when editing default user collection type' do
        let(:title_old) { user_collection_type.title }
        let(:description_old) { user_collection_type.description }
        let(:title_new) { 'User Collection modified' }
        let(:description_new) { 'Change in description for user collection type.' }

        before do
          user_collection_type
          login_as admin_user
          visit "/admin/collection_types/#{user_collection_type.id}/edit"
        end

        it 'allows editing of metadata, but not settings', :js do
          expect(page).to have_content "Edit Collection Type: #{title_old}"

          # confirm metadata fields have original values
          expect(page).to have_selector "input#collection_type_title[value='#{title_old}']"
          expect(page).to have_selector 'textarea#collection_type_description', text: description_old

          # set values and save
          fill_in('Type name', with: title_new)
          fill_in('Type description', with: description_new)

          click_button('Save changes')

          expect(page).to have_content "Edit Collection Type: #{title_new}"

          # confirm values were set
          expect(page).to have_selector "input#collection_type_title[value='#{title_new}']"
          expect(page).to have_selector 'textarea#collection_type_description', text: description_new

          click_link('Settings', href: '#settings')

          # confirm default user collection checkboxes are set to appropriate values
          expect(page).to have_checked_field('collection_type_nestable', disabled: true)
          expect(page).to have_checked_field('collection_type_brandable', disabled: true)
          expect(page).to have_checked_field('collection_type_discoverable', disabled: true)
          expect(page).to have_checked_field('collection_type_sharable', disabled: true)
          expect(page).to have_unchecked_field('collection_type_share_applies_to_new_works', disabled: true)
          expect(page).to have_checked_field('collection_type_allow_multiple_membership', disabled: true)

          # confirm all admin_set only checkboxes are off and disabled
          expect(page).to have_unchecked_field('collection_type_require_membership', disabled: true)
          expect(page).to have_unchecked_field('collection_type_assigns_workflow', disabled: true)
          expect(page).to have_unchecked_field('collection_type_assigns_visibility', disabled: true)
        end
      end

      context 'when editing admin set collection type' do
        let(:title_old) { admin_set_type.title }
        let(:description_old) { admin_set_type.description }
        let(:description_new) { 'Change in description for admin set collection type.' }

        before do
          admin_set_type
          login_as admin_user
          visit "/admin/collection_types/#{admin_set_type.id}/edit"
        end

        it 'allows editing of metadata except title, but not settings', :js do
          expect(page).to have_content "Edit Collection Type: #{title_old}"

          # confirm metadata fields have original values
          expect(page).to have_field("collection_type_title", disabled: true)
          expect(page).to have_selector 'textarea#collection_type_description', text: description_old

          # set values and save
          fill_in('Type description', with: description_new)

          click_button('Save changes')

          expect(page).to have_content "Edit Collection Type: #{title_old}"

          # confirm values were set
          expect(page).to have_selector 'textarea#collection_type_description', text: description_new

          click_link('Settings', href: '#settings')

          # confirm default user collection checkboxes are set to appropriate values
          expect(page).to have_unchecked_field('collection_type_nestable', disabled: true)
          expect(page).to have_unchecked_field('collection_type_discoverable', disabled: true)
          expect(page).to have_checked_field('collection_type_sharable', disabled: true)
          expect(page).to have_checked_field('collection_type_share_applies_to_new_works', disabled: true)
          expect(page).to have_unchecked_field('collection_type_allow_multiple_membership', disabled: true)

          # confirm all admin_set only checkboxes are off and disabled
          expect(page).to have_checked_field('collection_type_require_membership', disabled: true)
          expect(page).to have_checked_field('collection_type_assigns_workflow', disabled: true)
          expect(page).to have_checked_field('collection_type_assigns_visibility', disabled: true)
        end
      end
    end

    context 'when collections exist of this type' do
      before do
        FactoryBot.valkyrie_create(:hyku_collection, collection_type_gid: exhibit_collection_type.to_global_id.to_s)

        exhibit_collection_type
        login_as admin_user
        visit "/admin/collection_types/#{exhibit_collection_type.id}/edit"
      end

      it 'all settings are disabled', :js, ci: 'skip' do
        expect(exhibit_collection_type.collections.any?).to be true

        click_link('Settings', href: '#settings')

        # confirm all checkboxes are disabled
        expect(page).to have_field('collection_type_nestable', disabled: true)
        expect(page).to have_field('collection_type_brandable', disabled: true)
        expect(page).to have_field('collection_type_discoverable', disabled: true)
        expect(page).to have_field('collection_type_sharable', disabled: true)
        expect(page).to have_field('collection_type_share_applies_to_new_works', disabled: true)
        expect(page).to have_field('collection_type_allow_multiple_membership', disabled: true)
        expect(page).to have_field('collection_type_require_membership', disabled: true)
        expect(page).to have_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_field('collection_type_assigns_visibility', disabled: true)
      end
    end
  end

  describe 'delete collection type' do
    context 'when there are no collections of this type' do
      let!(:empty_collection_type) { create(:collection_type, title: 'Empty Type', creator_user: admin_user) }
      let!(:delete_modal_text) do
        'Deleting this collection type will permanently remove the type and its settings from the repository. ' \
        'Are you sure you want to delete this collection type?'
      end
      let!(:deleted_flash_text) { "The collection type #{empty_collection_type.title} has been deleted." }

      before do
        login_as admin_user
        visit '/admin/collection_types'
      end

      it 'shows warning, deletes collection type, and shows flash message on success', :js do
        expect(page).to have_content(empty_collection_type.title)

        find(:xpath, "//tr[td[contains(.,'#{empty_collection_type.title}')]]/td/button", text: 'Delete').click

        within('div#deleteModal') do
          expect(page).to have_content(delete_modal_text)
          click_button('Delete')
        end

        within('.alert-success') do
          expect(page).to have_content(deleted_flash_text)
        end

        within('.collection-types-table') do
          expect(page).not_to have_content(empty_collection_type.title)
        end
      end
    end

    context 'when collections exist of this type' do
      let!(:not_empty_collection_type) { create(:collection_type, title: 'Not Empty Type', creator_user: admin_user) }
      let!(:collection) do
        FactoryBot.valkyrie_create(
          :hyku_collection,
          user: admin_user,
          collection_type_gid: not_empty_collection_type.to_global_id.to_s
        )
      end
      # OVERRIDE: split deny_delete_modal_text into two variables since the test was failing over the newline character
      let(:deny_delete_modal_text_1) do
        'You cannot delete this collection type because one or more collections of this type have already been created.'
      end
      let(:deny_delete_modal_text_2) do
        'To delete this collection type, first ensure that all collections of this type have been deleted.'
      end

      before do
        login_as admin_user
        visit '/admin/collection_types'
      end

      it 'shows unable to delete dialog and forwards to All Collections with filter applied', :js, ci: 'skip' do
        expect(page).to have_content(not_empty_collection_type.title)

        expect(not_empty_collection_type.collections.to_a).to include(collection)

        # Yes this is very gross; we could have a data id on the TR instead we're jump through hoops for this
        find(:xpath, "//tr[td[contains(.,'#{not_empty_collection_type.title}')]]/td/button", text: 'Delete').click

        within('div#deleteDenyModal') do
          expect(page).to have_content(deny_delete_modal_text_1)
          expect(page).to have_content(deny_delete_modal_text_2)
          click_link('View collections of this type')
        end

        # forwards to Dashboard -> Collections -> All Collections
        within('.nav-tabs li.nav-item') do
          expect(page).to have_link('All Collections')
        end

        # filter is applied
        within('div#appliedParams') do
          expect(page).to have_content('Filtering by:')
          expect(page).to have_content('Type')
          expect(page).to have_content(not_empty_collection_type.title)
        end

        # collection of this type is in the list of collections
        expect(page).to have_content(collection.title.first)

        expect(not_empty_collection_type.reload.collections.to_a).to include(collection)
      end
    end
  end

  # OVERRIDE: new (non-hyrax) test cases below
  describe 'default collection type participants' do
    let(:title) { 'Title Test' }

    before do
      FactoryBot.create(
        :group,
        name: 'town_of_bedrock',
        humanized_name: 'Town of Bedrock'
      )
      FactoryBot.create(:user, email: 'user@example.com')

      login_as admin_user
      visit '/admin/collection_types/new'
    end

    context 'when creating a collection type' do
      it "includes non-role group access_grants to render in tables" do
        fill_in 'Type name', with: title
        click_button 'Save'
        expect(page).to have_content("The collection type #{title} has been created.")

        # click the Participants tab and ensure the heading has rendered
        click_link 'Participants'
        expect(page).to have_content 'Add Participants'

        # select the non-role group, assign role 'Manager', and add it to the collection type
        select("Town of Bedrock", from: 'collection_type_participant_agent_id')
        select("Manager", from: 'collection_type_participant_access', match: :first)
        within('.section-participants') do
          click_button('Add', match: :first)
        end

        # wait one second for the item to populate in the table and check for it's existence
        sleep 1
        expect(page).to have_content("Participants Updated")
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="town_of_bedrock"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td data-agent="town_of_bedrock">Town Of Bedrock</td>')
      end

      it 'excludes default role access_grants from rendering in tables' do
        fill_in 'Type name', with: title
        click_button 'Save'
        expect(page).to have_content("The collection type #{title} has been created.")

        click_link 'Participants'

        expect(page.html).not_to include('<td data-agent="collection_manager">Collection Manager</td>')
        expect(page.html).not_to include('<td data-agent="collection_editor">Collection Editor</td>')
        expect(page.html).not_to include('<td data-agent="collection_reader">Collection Reader</td>')
      end

      it "includes user access_grants to render in tables" do # rubocop:disable RSpec/ExampleLength
        fill_in 'Type name', with: title
        click_button 'Save'
        expect(page).to have_content("The collection type #{title} has been created.")

        click_link 'Participants'
        expect(page).to have_content 'Add Participants'

        # within the typeahead input the first two characters of the user's
        # email and wait one second for the item to populate in the table
        within('#s2id_collection_type_participant_agent_id') do
          fill_in "s2id_autogen1", with: 'us'
          sleep 1
        end

        # check for the existence of the user's email from the typeahead dropdown menu
        within('#select2-drop') do
          within('.select2-results', match: :first) do
            within('.select2-result', match: :first) do
              find('.select2-result-label', text: 'user@example.com').click
            end
          end
        end

        # from the add user form select the value 'Manager' from the dropdown menu and click the 'Add' button
        within('.section-participants') do
          last_container = all('.form-add-participants-wrapper').last
          within(last_container) do
            select("Manager", from: 'collection_type_participant_access')
            click_button('Add')
          end
        end

        # wait one second for the item to populate in the table and check for it's existence
        sleep 1
        expect(page).to have_content("Participants Updated")
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="user@example.com"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td data-agent="user@example.com">user@example.com</td>')
        expect(manager_row_html).to include('<td>User</td>')
      end
    end
  end
end
