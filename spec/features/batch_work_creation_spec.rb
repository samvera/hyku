# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch Work Creation', type: :feature, js: true, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }
  # Managed by `user`, so it is offered in the Relationships collection picker.
  let!(:deposit_collection) do
    FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Batch Deposit Collection'])
  end
  let!(:share_user) { create(:user, email: 'batch-share-target@example.com') }
  let!(:sharing_group) { create(:group, name: 'batch_sharing_group', humanized_name: 'Batch Sharing Group') }
  let(:admin_set) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

  before do
    # Default groups may already exist; create them idempotently.
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    admin_set
    Site.update(institution_name: 'Test Institution')
    # Batch upload is gated behind this Flipflop feature.
    allow(Flipflop).to receive(:batch_upload?).and_return(true)
    login_as user, scope: :user
  end

  # Manual test plan: "Dashboard Works New by Batch Page" — sidebar requirements,
  # visibility options, and the Files, Descriptions, Relationships, Sharing tabs.
  it 'shows the batch requirements, visibility options, and all deposit tabs' do
    visit '/batch_uploads/new?payload_concern=GenericWork'
    expect(page).to have_content('Add New Works by Batch')

    # Sidebar: requirements for creating the batch work
    within('#form-progress ul.requirements') do
      expect(page).to have_css('#required-metadata', text: 'Describe your work')
      expect(page).to have_css('#required-agreement', text: 'Check deposit agreement')
      # Hyku sets config.work_requires_files = false (config/initializers/hyrax.rb), so the
      # "Add files" requirement is not rendered (the page's other "Add files" text is the
      # Files tab button). spec/features/work_new_form_spec.rb covers it with the config on.
      expect(page).not_to have_css('#required-files')
    end

    # Sidebar: visibility options. "Institution" shows the site's institution name.
    expect(page).to have_css("input[type='radio'][value='open']")
    expect(page).to have_css("input[type='radio'][value='authenticated']")
    expect(page).to have_css("input[type='radio'][value='embargo']")
    expect(page).to have_css("input[type='radio'][value='lease']")
    expect(page).to have_css("input[type='radio'][value='restricted']")
    within('.set-access-controls') do
      expect(page).to have_css('label', text: 'Public')
      expect(page).to have_css('label', text: 'Test Institution')
      expect(page).to have_css('label', text: 'Embargo')
      expect(page).to have_css('label', text: 'Lease')
      expect(page).to have_css('label', text: 'Private')
    end

    # Files tab
    click_link 'Files'
    expect(page).to have_content('Add files')
    expect(page).to have_content('Add folder')

    # Descriptions tab: Creator is the only primary field (batch works get their
    # title from the filename). Keyword and Rights Statement live in the collapsed
    # "Additional fields" section and only appear once it is expanded.
    click_link 'Descriptions'
    expect(page).to have_field('Creator')
    expect(page).to have_selector(:link_or_button, 'Additional fields')
    click_on 'Additional fields'
    expect(page).to have_field('Keyword')
    expect(page).to have_select('Rights Statement')

    # Relationships tab: Administrative Set and collection selection. The collection
    # picker's native <select> is hidden behind its select2 widget, so visible: :all.
    click_link 'Relationships'
    expect(page).to have_select('Administrative Set')
    expect(page).to have_css("select[name='member_of_collection_ids']", visible: :all)

    # Sharing tab
    click_link 'Sharing'
    expect(page).to have_content('Add Sharing')
    expect(page).to have_css('fieldset.permission-add-group')
    expect(page).to have_css('fieldset.permission-add-user')
  end

  # Manual Test Plan: "Dashboard Works New by Batch Page" > Files. Each uploaded file gets
  # its own row (hyrax/uploads/_js_templates batch-template-download).
  it 'shows per-file display label and resource type controls, sets all resource types, and deletes a file' do
    visit '/batch_uploads/new?payload_concern=GenericWork'
    click_link 'Files'
    within('div#add-files') do
      attach_file('files[]', File.join(file_fixture_path, 'hyrax', 'image.jp2'), visible: false)
    end
    jp2_row = find('tr.template-download', text: 'image.jp2')
    within('div#add-files') do
      attach_file('files[]', Rails.root.join('spec', 'fixtures', 'images', 'world.png'), visible: false)
    end
    png_row = find('tr.template-download', text: 'world.png')

    expect(jp2_row).to have_css('.size', text: '11.04 KB')
    expect(png_row).to have_css('.size', text: '4.22 KB')
    # Display label defaults to the file name and is editable.
    expect(jp2_row).to have_field('Display label', with: 'image.jp2')
    expect(png_row).to have_field('Display label', with: 'world.png')
    jp2_row.fill_in 'Display label', with: 'Interview transcript, side A'
    expect(jp2_row).to have_field('Display label', with: 'Interview transcript, side A')

    # "Set all to this Resource Type" copies one file's selection to every file.
    expect(png_row.find('select.resource_type_dropdown').value).to be_empty
    jp2_row.select 'Article', from: jp2_row.find('select.resource_type_dropdown')[:id]
    jp2_row.click_button 'Set all to this Resource Type'
    expect(png_row.find('select.resource_type_dropdown').value).to eq(['Article'])

    # Delete removes just that file from the batch.
    png_upload = Hyrax::UploadedFile.where(user:).find { |f| f.file.file.original_filename == 'world.png' }
    png_row.click_button 'Delete'
    expect(page).not_to have_css('tr.template-download', text: 'world.png')
    expect(page).to have_css('tr.template-download', text: 'image.jp2')
    expect(Hyrax::UploadedFile.exists?(png_upload.id)).to be false
  end

  # Manual Test Plan: "Dashboard Works New by Batch Page" > Relationships.
  it 'adds a chosen collection to the list with a Remove from collection control' do
    visit '/batch_uploads/new?payload_concern=GenericWork'
    click_link 'Relationships'

    expect(page).to have_select('Administrative Set', selected: admin_set.title.first)
    within("[data-behavior='collection-relationships']") do
      expect(page).not_to have_css('tbody td', text: 'Batch Deposit Collection')
      find('.select2-container.collection-select2').click
    end
    find('.select2-drop-active .select2-result-label', text: 'Batch Deposit Collection').click
    within("[data-behavior='collection-relationships']") do
      click_link 'Add'
      row = find('tbody tr', text: 'Batch Deposit Collection')
      expect(row).to have_button('Remove from collection')
    end
  end

  # Manual Test Plan: "Dashboard Works New by Batch Page" > Sharing.
  it 'shares with a group at a chosen access level and notes that permissions are not yet saved' do
    visit '/batch_uploads/new?payload_concern=GenericWork'
    click_link 'Sharing'

    expect(page).to have_content('Currently Shared With')
    expect(page).to have_css('#file_permissions', text: 'Depositor')
    expect(page).not_to have_css('tr', text: sharing_group.name)
    expect(page).to have_css('#save_perm_note', visible: :hidden)

    within('fieldset.permission-add-group') do
      expect(page).to have_select('new_group_permission_skel', with_options: ['View/Download', 'Edit'])
      select 'Batch Sharing Group', from: 'new_group_name_skel'
      select 'View/Download', from: 'new_group_permission_skel'
      click_button 'Add'
    end

    expect(page).to have_css('#save_perm_note', visible: :visible,
                                                text: 'Permissions are not saved until the "Save" button is pressed')
    expect(page).to have_css('tr', text: %r{View/Download\s+#{sharing_group.name}})
  end

  # The user picker searches GET /users.json, which Hyku only allows for users who may read
  # Users; the regular-user failure is pending in spec/features/work_new_form_spec.rb.
  context 'as a depositor permitted to search users (user_reader role)' do
    let(:user) { create(:user, roles: %i[work_depositor user_reader]) }

    it 'shares with a user at a chosen access level' do
      visit '/batch_uploads/new?payload_concern=GenericWork'
      click_link 'Sharing'
      expect(page).not_to have_css('tr', text: share_user.email)

      within('fieldset.permission-add-user') do
        expect(page).to have_select('new_user_permission_skel', with_options: ['View/Download', 'Edit'])
      end
      find('#s2id_new_user_name_skel').click
      find('.select2-drop-active input.select2-input').fill_in(with: share_user.email)
      find('.select2-drop-active .select2-result-label', text: share_user.email).click
      select 'Edit', from: 'new_user_permission_skel'
      click_button 'add_new_user_skel'

      expect(page).to have_css('#save_perm_note', visible: :visible)
      expect(page).to have_css('tr', text: /Edit\s+#{Regexp.escape(share_user.email)}/)
    end
  end

  # A completed form (file, required metadata, admin set, agreement) is accepted
  # and shows the background-processing confirmation. Works are created
  # asynchronously, so this asserts the flash rather than a work count.
  #
  # Remove this comment and change `xit` back to `it` when issue #3427 is fixed.
  # KNOWN INTERMITTENT FAILURE (CI only, non-flexible mode): the Save button (with_files_submit)
  # sometimes stays disabled, so one of the form's requirements did not register. The cause is
  # not yet known; it passes locally in both modes. Disabled rather than pending, because it usually passes.
  xit 'accepts the batch for processing when the form is completed and saved' do
    visit '/batch_uploads/new?payload_concern=GenericWork'

    click_link 'Files'
    within('div#add-files') do
      attach_file('files[]', File.join(file_fixture_path, 'hyrax', 'image.jp2'), visible: false)
    end
    # A Delete control appears once the upload finishes; wait for it before saving.
    expect(page).to have_selector(:link_or_button, 'Delete')

    click_link 'Descriptions'
    fill_in 'Creator', with: 'Batch Creator'
    # Keyword and Rights Statement are in the collapsed "Additional fields" section.
    click_on 'Additional fields'
    fill_in 'Keyword', with: 'oral history'
    select 'In Copyright', from: 'Rights Statement'

    click_link 'Relationships'
    select admin_set.title.first, from: 'Administrative Set'

    # Choosing Public expands the publishing warning, confirming the selection registered.
    find("input[type='radio'][value='open']").click
    expect(page).to have_content('making something visible to the world')

    find('#agreement').click
    click_button('with_files_submit')

    expect(page).to have_content('being processed')
  end
end
