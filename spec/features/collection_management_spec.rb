# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection Management', type: :feature, js: true, clean: true do
  let(:user) { create(:user, roles: [:collection_manager]) }

  before do
    login_as user
  end

  it 'creates, edits, brands, shares, and deletes a collection' do
    visit '/dashboard/my/collections'
    click_link 'Add New Collection'
    fill_in 'Title', with: 'Test Collection'
    click_button 'Save'
    expect(page).to have_content('Test Collection')
    click_link 'Edit', match: :first
    fill_in 'Abstract or Summary', with: 'A summary.'
    click_button 'Save'
    expect(page).to have_content('A summary.')
    click_link 'Branding'
    attach_file('Banner image', Rails.root.join('spec/fixtures/files/banner.png'), visible: false) if page.has_field?('Banner image')
    attach_file('Logo image', Rails.root.join('spec/fixtures/files/logo.png'), visible: false) if page.has_field?('Logo image')
    fill_in 'Link URL', with: 'https://example.com' if page.has_field?('Link URL')
    fill_in 'Alt Text', with: 'Logo Alt' if page.has_field?('Alt Text')
    click_button 'Save'
    click_link 'Sharing'
    fill_in 'Search users', with: 'shareuser@example.com'
    click_button 'Add'
    expect(page).to have_content('shareuser@example.com')
    click_link 'Delete', match: :first
    expect(page).not_to have_content('shareuser@example.com')
    click_link 'Delete Collection', match: :first
    expect(page).not_to have_content('Test Collection')
  end

  # ------------------------------------------------------------------
  # Grounded coverage for the Manual Test Plan excerpt below.
  # Selectors/labels/routes mirror app/views/hyrax/dashboard/collections,
  # app/views/hyrax/admin/collection_types, and existing passing specs
  # (collection_manager_role_spec, collection_type_spec, collection_spec).
  # ------------------------------------------------------------------

  describe 'Dashboard collections index page' do
    # Owned + managed via the default collection_manager edit group (see hyku_collection factory)
    let!(:collection) do
      FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Managed Collection Alpha'])
    end

    it 'shows the Add New Collection control, count, and a search bar' do
      visit '/dashboard/collections'

      expect(page).to have_selector('#add-new-collection-button', text: 'Add New Collection')
      # count-display uses hyrax.my.count.collections.you_manage for a non-admin manager
      expect(page).to have_content('you can manage in the repository')
      # search bar (hyrax/my/_search_form)
      expect(page).to have_selector('input#search-field-header')
      expect(page).to have_selector('button#search-submit-header')
    end

    it 'renders the managed collections table with the expected column headers' do
      visit '/dashboard/collections'

      expect(page).to have_selector('table#collections-list-table')
      within('table#collections-list-table thead') do
        expect(page).to have_content('Title')
        expect(page).to have_content('Type')
        expect(page).to have_content('Last modified')
        expect(page).to have_content('Items')
        expect(page).to have_content('Visibility')
        expect(page).to have_content('Actions')
      end
    end

    it 'lists a manageable collection with View/Edit/Delete/Add to collection actions' do
      visit '/dashboard/collections'

      within('table#collections-list-table') do
        expect(page).to have_content('Managed Collection Alpha')
      end

      within("#document_#{collection.id}") do
        first('button.dropdown-toggle').click
      end

      expect(page).to have_link('View collection')
      expect(page).to have_link('Edit collection')
      expect(page).to have_link('Delete collection')
      # "Add to collection" only renders for nestable types (user collection type is nestable)
      expect(page).to have_link('Add to collection')
    end
  end

  describe 'Dashboard collection new page' do
    before do
      # Ensure the default user collection type exists so the create form has a type
      FactoryBot.create(:user_collection_type)
      visit '/dashboard/collections/new'
    end

    it 'shows the required Title field and an Abstract or Summary field' do
      expect(page).to have_selector('input#collection_title')
      expect(page).to have_selector('input#collection_title[required]')
      expect(page).to have_field('Abstract or Summary', visible: :all)
    end

    it 'shows Additional fields, Add another / Remove controls, Save and Cancel' do
      expect(page).to have_link('Additional fields')
      # multi-value descriptor fields (hydra-editor) with JS-injected controls
      expect(page).to have_selector('.multi_value')
      expect(page).to have_selector('.controls-add-text', text: 'Add another', visible: :all)
      expect(page).to have_selector('button.remove', visible: :all)
      # Save creates the collection; Cancel returns to the collections index
      expect(page).to have_button('Save')
      expect(page).to have_link('Cancel', href: %r{/dashboard/my/collections})
    end
  end

  describe 'Dashboard collection edit page tabs' do
    let!(:collection) do
      FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Editable Collection'])
    end

    before { visit "/dashboard/collections/#{collection.id}/edit" }

    context 'Description tab' do
      it 'shows the metadata form, Additional fields, Save and Cancel' do
        expect(page).to have_selector('#description input#collection_title')
        expect(page).to have_link('Additional fields')
        expect(page).to have_button('Save changes')
        expect(page).to have_link('Cancel', href: "/dashboard/collections/#{collection.id}?locale=en")
      end
    end

    context 'Branding tab' do
      it 'shows banner and logo upload controls' do
        click_link 'Branding'

        within('#branding') do
          expect(page).to have_content('Branding')
          expect(page).to have_content('Banner')
          expect(page).to have_content('Logo')
          # file inputs for banner/logo/thumbnail uploads + Choose File buttons
          expect(page).to have_selector("input[type='file']", visible: :all)
          expect(page).to have_content('Choose File')
        end
      end
    end

    context 'Discovery tab' do
      it 'shows the three visibility radios plus Save and Cancel' do
        click_link 'Discovery'

        within('.set-access-controls') do
          expect(page).to have_selector('input#collection_visibility_open')          # Public
          expect(page).to have_selector('input#collection_visibility_authenticated') # Institution
          expect(page).to have_selector('input#collection_visibility_restricted')    # Private
        end
        expect(page).to have_button('Save changes')
        expect(page).to have_link('Cancel', href: "/dashboard/collections/#{collection.id}?locale=en")
      end
    end

    context 'Sharing tab' do
      it 'shows add group/user forms and Managers/Depositors/Viewers sections' do
        click_link 'Sharing'

        within('#sharing') do
          expect(page).to have_content('Add Sharing')
          expect(page).to have_content('Add group')
          expect(page).to have_content('Add user')
          expect(page).to have_field('permission_template_access_grants_attributes_0_agent_id')
          expect(page).to have_content('Currently Shared With')
          expect(page).to have_content('Managers')
          expect(page).to have_content('Depositors')
          expect(page).to have_content('Viewers')
        end
      end
    end
  end

  describe 'Settings -> Collection Types (admin)' do
    let(:user) { create(:admin) }
    let!(:exhibit_type) do
      create(:collection_type, title: 'Exhibit Type', description: 'An exhibit type.', creator_user: user)
    end

    before { FactoryBot.create(:admin_group) }

    context 'index page' do
      before { visit '/admin/collection_types' }

      it 'shows the count, Create new collection type button, and edit/delete controls' do
        expect(page).to have_content('collection type')
        expect(page).to have_link('Create new collection type')
        within('.collection-types-table') do
          expect(page).to have_content('Exhibit Type')
          expect(page).to have_link('Edit')
          # custom (non-default) types get a Delete button
          expect(page).to have_button('Delete')
        end
      end
    end

    context 'new page' do
      before { visit '/admin/collection_types/new' }

      it 'shows required Type name, Type description, Save and Cancel' do
        expect(page).to have_content('Create New Collection Type')
        expect(page).to have_selector('input#collection_type_title')
        expect(page).to have_selector('textarea#collection_type_description')
        expect(page).to have_button('Save')
        expect(page).to have_link('Cancel', href: %r{/admin/collection_types})
      end
    end

    context 'edit page' do
      before { visit "/admin/collection_types/#{exhibit_type.id}/edit" }

      it 'exposes Description, Settings, Participants and Badge Color tabs' do
        expect(page).to have_link('Description', href: '#metadata')
        expect(page).to have_link('Settings', href: '#settings')
        expect(page).to have_link('Participants', href: '#participants')
        expect(page).to have_link('Badge Color', href: '#appearance')
      end

      it 'shows disabled admin-set-only checkboxes on the Settings tab' do
        click_link('Settings', href: '#settings')

        expect(page).to have_unchecked_field('collection_type_require_membership', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_visibility', disabled: true)
      end

      it 'shows the participants add-group/add-user forms and Manager/Creator lists' do
        click_link('Participants', href: '#participants')

        within('.section-participants') do
          expect(page).to have_content('Add Participants')
          expect(page).to have_select('collection_type_participant_agent_id')
        end
        # managers-table renders because the admin group is a default Manager of every collection type
        expect(page).to have_selector('table.managers-table')
        expect(page).to have_content('Creators')
      end

      it 'shows a color picker on the Badge Color tab plus Save and Cancel' do
        click_link('Badge Color', href: '#appearance')

        within('#appearance') do
          expect(page).to have_selector("input#collection_type_badge_color[type='color']")
        end
        expect(page).to have_button('Save changes')
        expect(page).to have_link('Cancel', href: %r{/admin/collection_types})
      end
    end
  end
end



# ## Dashboard My Collections Index Page
# [Back to TOC](#table-of-contents)

# ![image77](https://github.com/samvera/hyku/assets/19597776/9af90c67-0f28-4ac4-b3e5-0a84b584f045)

# ### As a user:

# - [ ] I can see the number of collections I own in the repository
# - [ ] I can see a button to add a New Collection
# - [ ] I can see several dropdowns to filter through collections
# - [ ] I can see a search bar to search for specific collections
# - [ ] I can see a table listing all collections I have permission to manage
# - [ ] I can see basic information re. each individual collection:
#   - [ ] Title
#   - [ ] Type
#   - [ ] Visibility
#   - [ ] Items
#   - [ ] Last modified
#   - [ ] Actions (View, Edit, Delete, Add to collection)

# ## Dashboard Collection New Page
# [Back to TOC](#table-of-contents)

# ![image57](https://github.com/samvera/hyku/assets/19597776/df577b13-2a60-47e6-9022-5316939664b0)

# ### As a user:

# - [ ] I can see a form to fill out basic information describing my new Collection
#   - [ ] Title (required)
#   - [ ] Abstract or Summary
# - [ ] I can see a button to display Additional fields for which to further describe my collection
# - [ ] I can see links to Add another input for most descriptors
#   - [ ] I can see links to Remove additional fields
# - [ ] I can see a Save button to create my new collection
# - [ ] I can see a link to Cancel my new Collection and redirect me back to the dashboard my collections index page

# ## Dashboard Collection Edit Page
# [Back to TOC](#table-of-contents)

# ### Description

# ![image17](https://github.com/samvera/hyku/assets/19597776/ae95babf-2e04-4bfe-9950-552bc3d3b475)

# ### As a user:

# - [ ] I can see a partial to alter / add to my collection’s descriptors
# - [ ] I can see a dropdown from which I can select a thumbnail for my collection
# - [ ] I can see a button for Additional fields
# - [ ] I can see links to Add another input for most descriptors
#   - [ ] I can see links to Remove additional fields
# - [ ] I can see a button to Save my changes
# - [ ] I can see a link to Cancel my edits, redirecting me to the Dashboard Collection’s show page

# ### Branding (User Collection only)

# ![image72](https://github.com/samvera/hyku/assets/19597776/75a906fe-4491-4362-b386-463755aad006)

# ### As a user:

# - [ ] I can see a description of how to add optional branding elements to my collection
# - [ ] I can see a button to upload a Banner image
#   - [ ] I can see a link to Remove an uploaded Banner image
# - [ ] I can see a button to upload a Logo image
#   - [ ] I can see an input to add a Link URL
#   - [ ] I can see an input to add Alt Text
#   - [ ] I can see a link to Remove an uploaded Logo image
# - [ ] I can see a button to Save my changes
# - [ ] I can see a link to Cancel my edits, which redirects me back to the Dashboard Collection show page

# ### Discovery (User Collection only)

# ![image6](https://github.com/samvera/hyku/assets/19597776/da92e6dd-e9c7-49cd-a10f-2c415be8ce37)

# ### As a user:

# - [ ] I can see an explanation of the different kinds of Discovery options
# - [ ] I can see three radio buttons to set the Visibility of my collection to:
#   - [ ] Public
#   - [ ] Institution
#   - [ ] Private
# - [ ] I can see a button to Save my changes
# - [ ] I can see a link to Cancel my edits, which redirects me back to the Dashboard Collection show page

# ### Sharing

# ![image44](https://github.com/samvera/hyku/assets/19597776/6a5ae284-a7c5-4865-9eaf-c8ee7581da29)

# ### As a user:

# - [ ] I can see a form to share my collection with specific groups and / or users
# - [ ] I can see a list of users / groups that I’ve shared my collection with as managers
# - [ ] I can see a list of users / groups that I’ve shared my collection with as depositors
# - [ ] I can see a list of users / groups that I’ve shared my collection with as viewers
# - [ ] I can see Remove buttons to remove individual users / groups from my collection
# - [ ] I can see a button to Save my changes
# - [ ] I can see a link to Cancel my edits, which redirects me back to the Dashboard Collection show page


# ## Settings → Collection Types Index Page
# [Back to TOC](#table-of-contents)

# ![image79](https://github.com/samvera/hyku/assets/19597776/c93ba62b-d4ce-4fb5-957c-9d71b508cb4b)

# ### As a admin:

# - [ ] I can see the total number of collection types I have in this repository
# - [ ] I can see a button to create a new collection type
# - [ ] I can see a link to display more information about collection types
# - [ ] I can see a list of all the current collection types within my repository
#   - [ ] I can see a button next to each collection type to Edit it
#   - [ ] I can see a button next to each custom, non-default collection type to Delete it

# ## Settings → Collection Types New Page
# [Back to TOC](#table-of-contents)

# ![image58](https://github.com/samvera/hyku/assets/19597776/abbc5b8c-1af7-495e-a16c-72275c2c374f)

# ### As an admin:

# - [ ] I can see a form to create a new collection types, describing it with:
#   - [ ] Type name (required)
#   - [ ] Type description
# - [ ] I can see a Save button to create my collection type
# - [ ] I can see a link to Cancel the creation of a new collection type, redirecting me back to the collection types index page

# ## Settings → Collection Types Edit Page
# [Back to TOC](#table-of-contents)

# ### Description

# ![image54](https://github.com/samvera/hyku/assets/19597776/882e65cb-95cb-457b-8d07-72c29a15de4e)

# ### As an admin:

# - [ ] I can see a form to edit a collection type, describing it with the attributes filled:
#   - [ ] Type name (required)
#   - [ ] Type description
# - [ ] I can see a Save Changes button to edit my collection type
# - [ ] I can see a link to Cancel the editing of a new collection type, redirecting me back to the collection types index page

# ### Settings

# ![image56](https://github.com/samvera/hyku/assets/19597776/ecf09ff6-878b-40f7-bb25-6621fcb10011)

# ### As an admin:

# - [ ] I can see several checkboxes describing different settings related to the collection type
#   - [ ] All the checkboxes are disabled, as they can only be changed upon creation of the collection type
# - [ ] I can see a Save button to create my collection type
# - [ ] I can see a link to Cancel the creation of a new collection type, redirecting me back to the collection types index page

# ### Participants

# ![image53](https://github.com/samvera/hyku/assets/19597776/9145c6c7-3a03-4a7a-979e-d23f3e47ce3a)

# ### As an admin:

# - [ ] I can see a form to add groups to have specific access to the collection type
# - [ ] I can see a form to add users to have specific access to the collection type
# - [ ] I can see a list of Managers of this collection type
#   - [ ] I can remove individual managers from this collection type
# - [ ] I can see a list of Creators of this collection type
#   - [ ] I can remove individual creators from this collection type
# - [ ] I can see a Save changes button
# - [ ] I can see a link to Cancel the edits on the collection type, redirecting me back to the collection types index page

# ### Badge Color

# ![image69](https://github.com/samvera/hyku/assets/19597776/6e099899-65c0-4cab-a86b-1ec62c2f511e)

# ### As an admin:

# - [ ] I can see a color picker input to select a badge color for the collection type
# - [ ] I can see a button to Save my changes
# - [ ] I can see a link to Cancel my changes, redirecting me back to the Collection Types Index page
