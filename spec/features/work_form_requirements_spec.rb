# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'New work form requirements', type: :feature, js: true, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }

  before do
    create(:registered_group)
    create(:admin_group)
    create(:editors_group)
    create(:depositors_group)
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set
    login_as user
  end

  it 'shows required metadata, file, relationship, and sharing controls' do
    visit new_hyrax_generic_work_path

    expect(page).to have_field('Title')
    expect(page).to have_field('Creator')
    expect(page).to have_field('Keyword')
    expect(page).to have_select('Rights Statement')
    expect(page).to have_link('Additional fields')
    expect(page).to have_link('Files')
    expect(page).to have_link('Relationships')
    expect(page).to have_link('Sharing')
  end

  it 'rejects a submission without required metadata' do
    visit new_hyrax_generic_work_path
    click_button 'Save'

    expect(page).to have_content("can't be blank")
  end

  # The manual test plan below documents the EDIT page for an existing work, where the
  # required fields are pre-filled. The owner (depositor) of the work can edit it. The
  # factory applies depositor metadata for `user`, so `user` owns and can edit this work.
  # Keyword and Rights Statement are primary terms on the GenericWork form (unlike the
  # batch form, where they live under "Additional fields"), so they render pre-populated
  # on the Descriptions tab without expanding the collapsed section.
  let(:existing_work) do
    create(:generic_work,
           user:,
           title: ['Editable Work Title'],
           creator: ['Edited Creator'],
           keyword: ['edit-keyword'],
           rights_statement: ['http://rightsstatements.org/vocab/InC/1.0/'])
  end

  describe 'the edit page for an existing work (Dashboard Work Edit Page)' do
    context 'Descriptions tab' do
      it 'shows the required fields pre-filled, a removable blank input, and Additional fields' do
        visit edit_hyrax_generic_work_path(existing_work)

        # Required fields are present and pre-populated with the work's saved values.
        expect(page).to have_field('Title', with: 'Editable Work Title')
        expect(page).to have_field('Creator', with: 'Edited Creator')
        expect(page).to have_field('Keyword', with: 'edit-keyword')
        expect(page).to have_select('Rights Statement', selected: 'In Copyright')

        # Multi-value fields render a trailing blank input under the filled one
        # (MultiValueInput appends an empty entry), plus a JS-injected Remove control.
        expect(page).to have_css("input[name='generic_work[title][]']", minimum: 2)
        expect(page).to have_css('button.remove')

        # Button to reveal the collapsed Additional fields section.
        expect(page).to have_link('Additional fields')
      end
    end

    context 'Files tab' do
      it 'shows the add-files controls and dropzone that render on load' do
        visit edit_hyrax_generic_work_path(existing_work)
        click_link 'Files'

        expect(page).to have_content('Add files')
        expect(page).to have_content('Add folder')
        # Drag-and-drop dropzone.
        expect(page).to have_css('div.dropzone')
        expect(page).to have_content('Drop files here')

        # The per-file Delete control only renders once a file is uploaded; it is supplied
        # by the download JS template (contains file name/size and a Delete button), which
        # is present in the DOM on load.
        expect(page).to have_css('script#template-download', visible: :all)
      end
    end

    context 'Relationships tab' do
      it 'shows admin set, collection and child-work pickers plus the child works list' do
        visit edit_hyrax_generic_work_path(existing_work)
        click_link 'Relationships'

        # Administrative Set dropdown.
        expect(page).to have_select('Administrative Set')

        # Collection search dropdown (select2-enhanced; the native control may be hidden).
        expect(page).to have_css("[data-behavior='collection-relationships']")
        expect(page).to have_css("[data-autocomplete='collection']", visible: :all)

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
        visit edit_hyrax_generic_work_path(existing_work)
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
          expect(page).to have_field('new_user_name_skel')
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
    end
  end
end


# ## Dashboard Work Edit Page
# [Back to TOC](#table-of-contents)

# ### Descriptions

# ![image50](https://github.com/samvera/hyku/assets/19597776/385552b8-3e8f-4797-9826-0b60cec3c0a3)

# ### As a user:

# - [ ] I can see the required fields already filled in:
#   - [ ] Title
#   - [ ] Creator
#   - [ ] Keyword
#   - [ ] Rights Statement
# - [ ] I can see blank input fields under the filled input fields with an option to remove them
# - [ ] I can see a button to add Additional Fields

# ### Files

# ![image9](https://github.com/samvera/hyku/assets/19597776/ced7da5d-642f-455b-8511-443f009cd0cc)

# ### As a user:

# - [ ] I can see a button to Add files
# - [ ] I can see a button to Add folder
# - [ ] I can see a dropzone to drag-and-drop files to upload
# - [ ] I can see the file name and file size of uploaded files
#   - [ ] I can see a Delete button next to each file to delete them individually

# ### Relationships

# ![image46](https://github.com/samvera/hyku/assets/19597776/c759f3ae-8760-4c36-b689-eebd9ef91d55)

# ### As a user:

# - [ ] I can see a dropdown to select which Administrative Set to deposit my work into
# - [ ] I can see a dropdown to search for existing collections for which to add my work to
# - [ ] I can see a list of all selected collections to add my works to
#   - [ ] I can see a Remove from collection button
# - [ ] I can see a dropdown to search for child works
# - [ ] I can see a button to Deposit a new work as a child of this work
# - [ ] I can see a list of all existing child works

# ### Sharing

# ![image78](https://github.com/samvera/hyku/assets/19597776/159b2ef8-3195-40d8-ad36-31c745bcd7ac)

# ### As a user:

# - [ ] I can see a form to add groups to have specific access to my created work
#   - [ ] Search for existing group to share with
#   - [ ] Choose Access level (View/Download, Edit)
#   - [ ] Add
# - [ ] I can see a form to add individual users to have specific access to my created work
#   - [ ] Search for existing user
#   - [ ] Choose Access level (View/Download, Edit)
#   - [ ] Add
# - [ ] I can see a list of all the groups / users I am currently sharing my works with, along with their respective access levels
# - [ ] If I add a new group / user, I can see a flash notification informing me that permissions aren’t save until the works are saved