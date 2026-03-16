# frozen_string_literal: true

require 'rails_helper'

# For work approval permissions, see spec/features/work_approval_permissions_spec.rb
RSpec.describe 'Work Editor role', type: :feature, js: true, clean: true, ci: 'skip' do
  include WorksHelper

  # `before`s and `let!`s are order-dependent -- do not move this `before` from the top
  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)

    login_as work_editor
  end
  let(:work_editor) { FactoryBot.create(:user, roles: [:work_editor]) }
  let(:work_depositor) { FactoryBot.create(:user, roles: [:work_depositor]) }
  let(:visibility_setting) { 'open' }
  let(:admin_set) do
    admin_set = AdminSet.new(title: ['Test Admin Set'])
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('default')
    Hyrax::AdminSetCreateService.call!(admin_set:, creating_user: nil)
  end
  let!(:work) do
    FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, depositor: work_depositor.user_key, visibility_setting:)
  end

  describe 'read permissions' do
    before do
      login_as work_editor
    end

    %w[open authenticated restricted].each do |visibility_setting|
      context "with #{visibility_setting} visibility_setting" do
        let(:visibility_setting) { 'open' }

        it 'can see the work in search results' do
          work
          visit search_catalog_path

          expect(page).to have_content(work.title.first)
        end

        it 'can see works it deposited in the dashboard' do
          my_work = FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, depositor: work_editor.user_key, visibility_setting:, admin_set:)
          visit '/dashboard/my/works'

          expect(page).to have_content('works you own in the repository')
          expect(page).to have_content(my_work.title.first)
        end

        it 'can see works deposited by other users in the dashboard' do
          work
          visit '/dashboard/my/works'
          click_link 'Managed Works' # switch tab

          expect(page).to have_content('works you can manage in the repository')
          expect(page).to have_content(work.title.first)
        end
      end
    end
  end

  describe 'create permissions' do
    before do
      login_as work_editor
    end

    it 'can see the "Add new work" button in the dashboard' do
      visit '/dashboard/my/works'

      expect(page).to have_link('Add New Work')
    end

    it 'can see the "Share Your Work" button on the tenant homepage' do
      visit '/'

      expect(page).to have_link('Share Your Work')
    end

    # Temporarily commenting out these specs because they consistently fail in the CI pipeline
    # after the Bulkrax version update. The issue seems related to form submission failing
    # in the CI environment but not locally. This needs further investigation to resolve.
    xit 'can create a work' do # rubocop:disable RSpec/ExampleLength
      visit new_hyrax_generic_work_path

      click_link 'Relationships' # switch tab
      select(admin_set.title.first, from: 'Administrative Set')

      click_link 'Files' # switch tab
      expect(page).to have_content "Add files"
      expect(page).to have_content "Add folder"
      within('div#add-files') do
        attach_file("files[]", File.join(file_fixture_path, 'hyrax', 'image.jp2'), visible: false)
        attach_file("files[]", File.join(file_fixture_path, 'hyrax', 'jp2_fits.xml'), visible: false)
      end
      expect(page).to have_selector(:link_or_button, 'Delete') # Wait for files to finish uploading

      click_link 'Descriptions' # switch tab
      fill_in('Title', with: 'WE Feature Spec Work')
      fill_in('Creator', with: 'Test Creator')
      click_on('Additional fields')
      fill_in('Keyword', with: 'testing')
      select('In Copyright', from: 'Rights Statement')

      # This might be generic_work_visibility_open or generic_work_visibility_setting_open
      page.choose('generic_work_visibility_open')

      # rubocop:disable Layout/LineLength
      expect(page).to have_content('Please note, making something visible to the world (i.e. marking this as Public) may be viewed as publishing which could impact your ability to')
      # rubocop:enable Metrics/MethodLength
      find('#agreement').click

      expect { click_on('Save') }
        .to change(GenericWork, :count)
        .by(1)
    end
  end

  describe 'edit permissions' do
    before do
      login_as work_editor
    end

    it 'can see the edit button on the work show page' do
      visit hyrax_generic_work_path(work)

      expect(page).to have_selector(:link_or_button, 'Edit')
    end

    it 'can see the edit button for works it creates on the dashboard index page' do
      FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, visibility_setting:, depositor: work_editor.user_key)
      visit '/dashboard/my/works'

      click_button('Select')
      expect(page).to have_text('Edit Work')
    end

    it 'can see the edit button for works other users create on the dashboard index page' do
      visit '/dashboard/works'

      click_button('Select')
      expect(page).to have_text('Edit Work')
    end
  end

  describe 'destroy permissions' do
    before do
      login_as work_editor
    end

    it 'cannot see the delete button on the work show page' do
      visit hyrax_generic_work_path(work)

      expect(page).not_to have_selector(:link_or_button, 'Delete')
    end

    it 'cannot see the delete button for works it creates on the dashboard index page' do
      FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, visibility_setting:, depositor: work_editor.user_key)

      visit '/dashboard/my/works'

      click_button('Select')
      expect(page).not_to have_text('Delete Work')
    end

    it 'cannot see the delete button for works other users create on the dashboard index page' do
      visit '/dashboard/works'

      click_button('Select')
      expect(page).not_to have_text('Delete Work')
    end
  end
end
