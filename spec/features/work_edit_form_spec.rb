# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work edit form', type: :feature, js: true, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }

  let!(:sharing_group) { create(:group, name: 'edit_form_sharing_group', humanized_name: 'Edit Form Sharing Group') }

  before do
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    login_as user
  end

  # The Manual Test Plan's "Dashboard Work Edit Page" documents the EDIT page for an
  # existing work, where the required fields are pre-filled. The owner (depositor) of the
  # work can edit it.
  # Title, Creator and Rights Statement are the primary fields; Keyword lives in the
  # collapsed "Additional fields" section, so it is checked after expanding that section.
  #
  # Hyku runs Hyrax::ValkyrieLazyMigration, so a GenericWork (ActiveFedora) and a
  # GenericWorkResource (Valkyrie) edit through the SAME /concern/generic_works/:id/edit
  # route and form. We run the edit-page expectations against both backings; each backing
  # context provides an editable `existing_work`.
  shared_examples 'the work edit page tabs' do
    context 'Descriptions tab' do
      it 'shows the required fields pre-filled, a removable blank input, and Additional fields' do
        visit "/concern/generic_works/#{existing_work.id}/edit"

        # Required fields are present and pre-populated with the work's saved values.
        expect(page).to have_field('Title', with: 'Field Notes from Lake Erie')
        expect(page).to have_field('Creator', with: 'Hargrove, Elena')
        expect(page).to have_select('Rights Statement', selected: 'In Copyright')

        # Multi-value fields render a trailing blank input under the filled one
        # (MultiValueInput appends an empty entry), plus a JS-injected Remove control.
        expect(page).to have_css("input[name='generic_work[title][]']", minimum: 2)
        expect(page).to have_css('button.remove')

        # The Additional fields button reveals the collapsed section, where Keyword is
        # also pre-populated.
        click_link 'Additional fields'
        expect(page).to have_field('Keyword', with: 'limnology')
      end
    end

    context 'Files tab' do
      it 'uploads a file, lists its name and size, and deletes it' do
        visit "/concern/generic_works/#{existing_work.id}/edit"
        click_link 'Files'

        within('div#add-files') do
          attach_file('files[]', Rails.root.join('spec', 'fixtures', 'hyrax', 'image.jp2'), visible: false)
        end

        row = find('tr.template-download', text: 'image.jp2')
        # jquery-fileupload formats 11,043 bytes as "11.04 KB".
        expect(row).to have_css('.size', text: '11.04 KB')
        expect(row).to have_button('Delete')
        uploaded = Hyrax::UploadedFile.where(user:).last
        expect(uploaded.file.file.original_filename).to eq('image.jp2')

        row.click_button('Delete')
        expect(page).not_to have_css('tr.template-download', text: 'image.jp2')
        expect(Hyrax::UploadedFile.exists?(uploaded.id)).to be false
      end
    end

    context 'Relationships tab' do
      it 'shows admin set, collection and child-work pickers plus the child works list' do
        visit "/concern/generic_works/#{existing_work.id}/edit"
        click_link 'Relationships'

        # Administrative Set dropdown.
        expect(page).to have_select('Administrative Set')

        # Collection search dropdown: a visible select2 widget backed by a hidden
        # select[name='member_of_collection_ids'], plus the list of collections the work
        # is currently in (where Remove controls appear for each selected collection).
        within("[data-behavior='collection-relationships']") do
          expect(page).to have_css('.select2-container.collection-select2')
          expect(page).to have_css("select[name='member_of_collection_ids']", visible: :all)
          expect(page).to have_content('This work is currently in these collections')
        end

        # Child-works search dropdown. This section only renders for a persisted work,
        # which is why it is exercised on the edit page rather than the new-work form.
        expect(page).to have_css("[data-behavior='child-relationships']")
        expect(page).to have_css("[data-autocomplete='work']", visible: :all)

        # Link to deposit a new work as a child of this work.
        expect(page).to have_link('Deposit new work as child of this work')

        # Table listing existing child works.
        expect(page).to have_content('This work currently contains these child works')
      end
    end

    context 'Sharing tab' do
      it 'shows the group and user add forms with access levels and the current shares' do
        visit "/concern/generic_works/#{existing_work.id}/edit"
        click_link 'Sharing'

        expect(page).to have_content('Add Sharing')

        # Group-add form: search for a group, choose an access level, Add.
        within('fieldset.permission-add-group') do
          expect(page).to have_css('#new_group_name_skel')
          expect(page).to have_select('new_group_permission_skel', with_options: ['View/Download', 'Edit'])
          expect(page).to have_css('#add_new_group_skel')
        end

        # User-add form: search for a user, choose an access level, Add.
        within('fieldset.permission-add-user') do
          # The user search is select2-enhanced, which hides the underlying input.
          expect(page).to have_css('#new_user_name_skel', visible: :all)
          expect(page).to have_select('new_user_permission_skel', with_options: ['View/Download', 'Edit'])
          expect(page).to have_css('#add_new_user_skel')
        end

        # List of current shares always shows the depositor.
        expect(page).to have_content('Currently Shared With')
        expect(page).to have_content('Depositor')

        # The "permissions aren't saved until the work is saved" note is present but hidden;
        # it is revealed by JS after a group/user is added.
        expect(page).to have_css('#save_perm_note', visible: :all)
      end

      it 'adds a group share, notes it is unsaved, and persists it when the work is saved' do
        visit "/concern/generic_works/#{existing_work.id}/edit"
        click_link 'Sharing'
        expect(page).not_to have_css('tr', text: sharing_group.name)
        expect(page).to have_css('#save_perm_note', visible: :hidden)

        within('fieldset.permission-add-group') do
          select 'Edit Form Sharing Group', from: 'new_group_name_skel'
          select 'Edit', from: 'new_group_permission_skel'
          click_button 'Add'
        end

        expect(page).to have_css('#save_perm_note', visible: :visible,
                                                    text: 'Permissions are not saved until the "Save" button is pressed')
        expect(page).to have_css('tr', text: /Edit\s+#{sharing_group.name}/)

        find('#agreement').check unless find('#agreement').checked?
        click_button 'with_files_submit'

        expect(page).to have_css('h1', text: 'Field Notes from Lake Erie')
        expect(Hyrax.query_service.find_by(id: existing_work.id).edit_groups).to include(sharing_group.name)
      end
    end
  end

  describe 'the edit page for an existing work (Dashboard Work Edit Page)' do
    context 'with an ActiveFedora-backed work' do
      # create(:generic_work, user:) applies depositor metadata, so `user` can edit.
      let(:existing_work) do
        create(:generic_work,
               user:,
               title: ['Field Notes from Lake Erie'],
               creator: ['Hargrove, Elena'],
               keyword: ['limnology'],
               rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/'])
      end

      it_behaves_like 'the work edit page tabs'
    end

    context 'with a Valkyrie-backed work' do
      # Grant the depositor edit access explicitly on the Valkyrie resource.
      let(:existing_work) do
        FactoryBot.valkyrie_create(:generic_work_resource,
                                   depositor: user.user_key,
                                   edit_users: [user.user_key],
                                   title: ['Field Notes from Lake Erie'],
                                   creator: ['Hargrove, Elena'],
                                   keyword: ['limnology'],
                                   rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/'])
      end

      it_behaves_like 'the work edit page tabs'

      # Relationships tab: the collections the work already belongs to are listed (from the
      # form's data-members) with a Remove control that asks for confirmation.
      context 'when the work is in a collection' do
        let(:collection) do
          FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Edit Form Member Collection'])
        end
        let(:existing_work) do
          FactoryBot.valkyrie_create(:generic_work_resource,
                                     depositor: user.user_key,
                                     edit_users: [user.user_key],
                                     title: ['Field Notes from Lake Erie'],
                                     member_of_collection_ids: [collection.id])
        end

        it 'lists the collection with a Remove control' do
          visit "/concern/generic_works/#{existing_work.id}/edit"
          click_link 'Relationships'

          within("[data-behavior='collection-relationships'] tbody") do
            row = find('tr', text: 'Edit Form Member Collection')
            expect(row).to have_button('Remove from collection')
            row.click_button('Remove from collection')
          end
          within('.confirm-remove-dialog') { click_button 'Remove' }
          expect(page).not_to have_css("[data-behavior='collection-relationships'] tbody tr",
                                       text: 'Edit Form Member Collection')
        end
      end
    end
  end
end
