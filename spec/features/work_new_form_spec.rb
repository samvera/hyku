# frozen_string_literal: true

require 'rails_helper'

# Manual Test Plan: "Dashboard Work New Page" (sidebar, Descriptions, Files, Relationships, Sharing).
# The older end-to-end version in spec/features/create_generic_work_spec.rb is disabled (xit);
# these examples exercise each tab's controls without submitting the form.
RSpec.describe 'New work form', type: :feature, js: true, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }
  let!(:share_user) { create(:user, email: 'new-form-share-target@example.com') }
  # The creating user manages the collection, so it is offered for deposit.
  let!(:collection) { FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['New Form Target Collection']) }
  let!(:sharing_group) { create(:group, name: 'new_form_sharing_group', humanized_name: 'New Form Sharing Group') }
  let(:admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

  before do
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    admin_set
    Site.update(institution_name: 'New Form Institution')
    login_as user
  end

  describe 'sidebar' do
    it 'lists the deposit requirements and offers every visibility option' do
      visit new_hyrax_generic_work_path

      within('#form-progress') do
        expect(page).to have_css('#required-metadata', text: 'Describe your work')
        expect(page).to have_css('#required-agreement', text: 'Check deposit agreement')
        # Hyku sets config.work_requires_files = false (config/initializers/hyrax.rb), so the
        # "Add files" requirement is not rendered by default; see the next example.
        expect(page).not_to have_css('#required-files')

        within('.set-access-controls') do
          expect(page).to have_css("input[type='radio'][name='generic_work[visibility]']", count: 5)
          expect(page).to have_css('label', text: 'Public')
          expect(page).to have_css('label', text: 'New Form Institution')
          expect(page).to have_css('label', text: 'Embargo')
          expect(page).to have_css('label', text: 'Lease')
          expect(page).to have_css('label', text: 'Private')

          # Embargo and Lease reveal their date/visibility controls when chosen.
          expect(page).not_to have_field('generic_work[embargo_release_date]')
          find("input[type='radio'][value='embargo']").click
          expect(page).to have_field('generic_work[embargo_release_date]')
          expect(page).to have_select('generic_work[visibility_after_embargo]')
          find("input[type='radio'][value='lease']").click
          expect(page).to have_field('generic_work[lease_expiration_date]')
          expect(page).to have_select('generic_work[visibility_after_lease]')
          find("input[type='radio'][value='restricted']").click
          expect(find("input[type='radio'][value='restricted']")).to be_checked
        end
      end
    end

    it 'shows an "Add files" requirement that completes once a file is uploaded, when files are required' do
      allow(Hyrax.config).to receive(:work_requires_files?).and_return(true)
      visit new_hyrax_generic_work_path

      expect(page).to have_css('#required-files.incomplete', text: 'Add files')
      click_link 'Files'
      within('div#add-files') do
        attach_file('files[]', Rails.root.join('spec', 'fixtures', 'images', 'world.png'), visible: false)
      end
      expect(page).to have_css('tr.template-download', text: 'world.png')
      expect(page).to have_css('#required-files.complete', text: 'Add files')
    end
  end

  describe 'Descriptions tab' do
    it 'shows the required fields and adds another input for a descriptor' do
      visit new_hyrax_generic_work_path

      expect(page).to have_field('Title')
      expect(page).to have_field('Creator')
      expect(page).to have_select('Rights Statement')
      click_link 'Additional fields'
      expect(page).to have_field('Keyword')

      # Each multi-value input gets an "Add another <field>" button.
      expect(page).to have_button('Add another Title')
      expect(page).to have_button('Add another Keyword')

      fill_in 'Creator', with: 'Okafor, Chiamaka'
      click_button 'Add another Creator'
      expect(all("input[name='generic_work[creator][]']").map(&:value)).to eq(['Okafor, Chiamaka', ''])
    end
  end

  describe 'Files tab' do
    it 'uploads a file, lists its name and size, and deletes it' do
      visit new_hyrax_generic_work_path
      click_link 'Files'

      expect(page).to have_button('Add files')
      expect(page).to have_button('Add folder')
      expect(page).to have_css('div.dropzone', text: 'Drop files here')

      within('div#add-files') do
        attach_file('files[]', Rails.root.join('spec', 'fixtures', 'images', 'world.png'), visible: false)
      end

      row = find('tr.template-download', text: 'world.png')
      # jquery-fileupload formats 4,218 bytes as "4.22 KB".
      expect(row).to have_css('.size', text: '4.22 KB')
      expect(row).to have_button('Delete')
      uploaded = Hyrax::UploadedFile.where(user:).last
      expect(uploaded.file.file.original_filename).to eq('world.png')

      row.click_button('Delete')
      expect(page).not_to have_css('tr.template-download', text: 'world.png')
      expect(Hyrax::UploadedFile.exists?(uploaded.id)).to be false
    end
  end

  describe 'Relationships tab' do
    it 'offers an Administrative Set dropdown and lists a selected collection with a Remove from collection button' do
      visit new_hyrax_generic_work_path
      click_link 'Relationships'

      expect(page).to have_select('Administrative Set', selected: admin_set.title.first)

      expect(page).not_to have_css('tbody tr', text: 'New Form Target Collection')
      find('.select2-container.collection-select2').click
      find('.select2-drop-active .select2-result-label', text: 'New Form Target Collection').click
      within("[data-behavior='collection-relationships']") { click_link 'Add' }

      row = find("[data-behavior='collection-relationships'] tbody tr", text: 'New Form Target Collection')
      expect(row).to have_button('Remove from collection')
    end
  end

  describe 'Sharing tab' do
    it 'shares with a group at a chosen access level and notes that permissions are not yet saved' do
      visit new_hyrax_generic_work_path
      click_link 'Sharing'

      expect(page).to have_content('Currently Shared With')
      expect(page).to have_css('#file_permissions', text: 'Depositor')
      expect(page).not_to have_css('tr', text: sharing_group.name)
      expect(page).to have_css('#save_perm_note', visible: :hidden)

      within('fieldset.permission-add-group') do
        expect(page).to have_select('new_group_permission_skel', with_options: ['View/Download', 'Edit'])
        select 'New Form Sharing Group', from: 'new_group_name_skel'
        select 'Edit', from: 'new_group_permission_skel'
        click_button 'Add'
      end

      expect(page).to have_css('#save_perm_note', visible: :visible,
                                                  text: 'Permissions are not saved until the "Save" button is pressed')
      # Hyku's tmpl-work-grant row: access label, then the group name.
      expect(page).to have_css('tr', text: /Edit\s+#{sharing_group.name}/)
    end

    # The user picker searches GET /users.json, which Hyku only allows for users who may read
    # Users (user_manager/user_reader); see the pending example below.
    context 'as a depositor permitted to search users (user_reader role)' do
      let(:user) { create(:user, roles: %i[work_depositor user_reader]) }

      it 'shares with a user at a chosen access level' do
        visit new_hyrax_generic_work_path
        click_link 'Sharing'
        expect(page).not_to have_css('tr', text: share_user.email)

        within('fieldset.permission-add-user') do
          expect(page).to have_select('new_user_permission_skel', with_options: ['View/Download', 'Edit'])
        end
        find('#s2id_new_user_name_skel').click
        find('.select2-drop-active input.select2-input').fill_in(with: share_user.email)
        find('.select2-drop-active .select2-result-label', text: share_user.email).click
        select 'View/Download', from: 'new_user_permission_skel'
        click_button 'add_new_user_skel'

        expect(page).to have_css('#save_perm_note', visible: :visible)
        expect(page).to have_css('tr', text: %r{View/Download\s+#{Regexp.escape(share_user.email)}})
      end
    end

    # Remove this comment and the `pending` call to re-enable this test when issue #3419 is fixed.
    # KNOWN APPLICATION ISSUE: GET /users.json is forbidden for a regular depositor, so the Sharing tab user
    # search finds no one. Fix goes in app/controllers/concerns/hyrax/users_controller_decorator.rb.
    it 'lets a regular depositor find a user in the Sharing tab user search' do
      pending('Hyku UsersControllerDecorator authorizes Hyrax::UsersController#index, so ' \
              'GET /users.json returns 403 for users without the user_manager/user_reader role')
      visit new_hyrax_generic_work_path
      click_link 'Sharing'
      find('#s2id_new_user_name_skel').click
      find('.select2-drop-active input.select2-input').fill_in(with: share_user.email)

      expect(page).to have_css('.select2-drop-active .select2-result-label', text: share_user.email)
    end
  end
end
