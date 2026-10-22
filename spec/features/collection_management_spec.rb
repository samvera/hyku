# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection Management', type: :feature, js: true, clean: true, flexible: :either do
  let(:user) { create(:user, roles: [:collection_manager]) }

  before do
    login_as user
  end

  # A collection manager creates a collection from My Collections, edits it, and deletes it.
  # (Branding, Discovery and Sharing are covered tab by tab further below.) Fields are
  # targeted by id because the collection form also has a hidden compound "Title" field.
  # Fails in flexible mode, where it may be expected to pass, so there may be a behavior gap:
  # ElementNotFound: Unable to find field "collection_title" that is not disabled.
  it 'creates, edits, and deletes a collection', flexible: false do
    # The "Add New Collection" link renders once a collection type the user may create exists.
    Hyrax::CollectionType.find_or_create_default_collection_type
    visit '/dashboard/my/collections'
    click_link 'Add New Collection'

    fill_in 'collection_title', with: 'Lifecycle Collection'
    fill_in 'collection_creator', with: 'Collection Creator'
    click_button 'Save'
    expect(page).to have_content('Collection was successfully created.')

    collection = Hyrax.query_service.find_all_of_model(model: Hyrax.config.collection_class)
                      .find { |c| c.title.first == 'Lifecycle Collection' }
    expect(collection).to be_present

    visit "/dashboard/collections/#{collection.id}/edit"
    fill_in 'collection_title', with: 'Renamed Lifecycle Collection'
    click_button 'Save changes'
    expect(page).to have_content('Collection was successfully updated.')

    visit "/dashboard/collections/#{collection.id}"
    expect(page).to have_content('Renamed Lifecycle Collection')
    accept_confirm { click_link_or_button 'Delete collection' }
    expect(page).to have_content('Collection was successfully deleted')
  end

  # ------------------------------------------------------------------
  # Grounded coverage for the Manual Test Plan's "Dashboard My Collections Index",
  # "Dashboard Collection New/Edit" and "Settings → Collection Types" pages.
  # Selectors/labels/routes mirror app/views/hyrax/dashboard/collections,
  # app/views/hyrax/admin/collection_types, and existing passing specs
  # (collection_manager_role_spec, collection_type_spec, collection_spec).
  # ------------------------------------------------------------------

  # The plan's "My Collections" index is /dashboard/my/collections (collections you own).
  # /dashboard/collections is Hyrax's "Managed Collections" tab, which for non-admins lists
  # only collections you manage but do not own, so an owned collection does not appear there.
  describe 'Dashboard collections index page' do
    # Owned + managed via the default collection_manager edit group (see hyku_collection factory)
    let!(:collection) do
      FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Managed Collection Alpha'])
    end

    it 'shows the Add New Collection control, count, and a search bar' do
      visit '/dashboard/my/collections'

      expect(page).to have_selector('#add-new-collection-button', text: 'Add New Collection')
      # count-display uses hyrax.my.count.collections.you_own (My Collections)
      expect(page).to have_content('1 collections you own in the repository')
      # search bar (hyrax/my/_search_form)
      expect(page).to have_selector('input#search-field-header')
      expect(page).to have_selector('button#search-submit-header')
    end

    it 'renders the managed collections table with the expected column headers' do
      visit '/dashboard/my/collections'

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
      visit '/dashboard/my/collections'

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

  # Manual Test Plan: "Dashboard My Collections Index Page" (filters, search, and row values).
  # The filter dropdowns are plain facet links, so these run without JS.
  describe 'Dashboard My Collections filters, search and rows', js: false do
    let(:exhibit_type) do
      create(:collection_type, title: 'Exhibit Type', creator_user: user, manager_user: user)
    end
    let!(:private_collection) do
      FactoryBot.valkyrie_create(:hyku_collection, user:, title: ['Private Alpha Collection'])
    end
    let!(:public_exhibit) do
      FactoryBot.valkyrie_create(:hyku_collection, :public, user:, title: ['Public Bravo Exhibit'],
                                                            collection_type_gid: exhibit_type.to_global_id.to_s)
    end

    before do
      # The Type column badge only renders when Site.account is present (nil in single-tenant runs).
      allow(Site).to receive(:account).and_return(create(:account))
    end

    def listed_collection_ids
      all('table#collections-list-table tbody tr').map { |row| row[:id] }
    end

    it "shows each collection's type, last modified date, item count and visibility in its row" do
      FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member,
                                 member_of_collection_ids: [public_exhibit.id], title: ['Exhibit member work'],
                                 visibility_setting: 'open')
      visit '/dashboard/my/collections'
      expect(page).to have_content('2 collections you own in the repository')

      within("#document_#{public_exhibit.id}") do
        expect(page).to have_link('Public Bravo Exhibit')
        expect(page).to have_css('td.collection_type', text: 'Exhibit Type')
        expect(page).to have_css('td.date', text: SolrDocument.find(public_exhibit.id.to_s).modified_date.to_s)
        expect(page).to have_css('td.date + td', exact_text: '1')       # Items
        expect(page).to have_css('td.date + td + td', exact_text: 'Public') # Visibility
      end
      within("#document_#{private_collection.id}") do
        expect(page).to have_link('Private Alpha Collection')
        expect(page).to have_css('td.collection_type', text: 'User Collection')
        expect(page).to have_css('td.date + td', exact_text: '0')
        expect(page).to have_css('td.date + td + td', exact_text: 'Private')
      end
    end

    it 'narrows the list with the Visibility filter' do
      visit '/dashboard/my/collections'
      expect(listed_collection_ids).to contain_exactly("document_#{private_collection.id}", "document_#{public_exhibit.id}")

      within('#visibility_ssi-dropdown-options') { click_link 'Public' }

      expect(listed_collection_ids).to eq(["document_#{public_exhibit.id}"])
      expect(page).to have_content('1 collections you own in the repository')
    end

    it 'narrows the list with the Collection Type filter' do
      visit '/dashboard/my/collections'

      within('#collection_type_gid_ssim-dropdown-options') { click_link 'User Collection' }

      expect(listed_collection_ids).to eq(["document_#{private_collection.id}"])
    end

    it 'searches for a specific collection from the search bar' do
      visit '/dashboard/my/collections'

      fill_in 'search-field-header', with: 'Bravo'
      click_button 'search-submit-header'

      expect(listed_collection_ids).to eq(["document_#{public_exhibit.id}"])
    end
  end

  describe 'Dashboard collection new page' do
    before do
      # Ensure the default user collection type exists so the create form has a type
      FactoryBot.create(:user_collection_type)
      visit '/dashboard/collections/new'
    end

    it 'shows the required Title field and an Abstract field' do
      expect(page).to have_selector('input#collection_title')
      expect(page).to have_selector('input#collection_title[required]')
      # Hyku labels the summary field "Abstract"; it is in the collapsed Additional fields.
      click_link 'Additional fields'
      expect(page).to have_field('Abstract')
    end

    it 'shows Additional fields, Add another / Remove controls, Save and Cancel' do
      expect(page).to have_link('Additional fields')
      # multi-value descriptor fields (hydra-editor) with JS-injected controls
      expect(page).to have_selector('.multi_value')
      expect(page).to have_selector('.controls-add-text', text: 'Add another', visible: :all)
      expect(page).to have_selector('button.remove', visible: :all)
      # Save creates the collection; Cancel returns to the collections index
      expect(page).to have_button('Save')
      click_link 'Cancel'
      expect(page).to have_current_path(%r{\A/dashboard/my/collections})
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

      it 'adds and removes descriptor inputs with Add another / Remove and saves the result' do
        within('div.collection_creator') do
          expect(page).to have_css('li.field-wrapper', count: 2)
          all('li.field-wrapper input')[1].set('Second Creator')
          find('button.add').click
          expect(page).to have_css('li.field-wrapper', count: 3)
          all('li.field-wrapper input')[2].set('Third Creator')

          all('li.field-wrapper')[1].find('button.remove').click
          expect(page).to have_css('li.field-wrapper', count: 2)
        end
        click_button 'Save changes'

        expect(page).to have_content('Collection was successfully updated.')
        expect(Hyrax.query_service.find_by(id: collection.id).creator)
          .to contain_exactly('An Interesting Person', 'Third Creator')
      end

      it 'offers a dropdown to select the collection thumbnail' do
        # Remove this comment and the `pending` call to re-enable this test when issue #5286 is fixed.
        # KNOWN APPLICATION ISSUE: thumbnail select renders only for ActiveFedora collections, not Valkyrie (Hyku's default).
        # Fix goes in Hyrax (samvera/hyrax): app/views/hyrax/dashboard/collections/_form.html.erb (overridden in Hyku there too).
        pending('collection[thumbnail_id] select is not rendered for Valkyrie collections')
        expect(page).to have_select('collection[thumbnail_id]')
      end
    end

    context 'Cancel on each tab' do
      it 'returns to the dashboard collection show page' do
        %w[Description Branding Discovery Sharing].each do |tab|
          visit "/dashboard/collections/#{collection.id}/edit"
          click_link tab
          click_link 'Cancel'
          expect(page).to have_current_path("/dashboard/collections/#{collection.id}?locale=en")
          expect(page).to have_link('Edit collection')
        end
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

      context 'with an uploaded banner and logo' do
        # Seed the branding records the upload step would create (the file is copied into branding storage).
        def seed_branding(role:, alt:, url: '')
          source = Rails.root.join('tmp', "#{role}-#{SecureRandom.hex(4)}.png")
          FileUtils.cp(Rails.root.join('spec', "fixtures", "images", "world.png"), source)
          CollectionBrandingInfo.new(collection_id: collection.id.to_s, filename: "#{role}.png", role:,
                                     alt_txt: alt, target_url: url).save(source.to_s)
        end

        def branding_for(role)
          CollectionBrandingInfo.where(collection_id: collection.id.to_s, role:)
        end

        before do
          seed_branding(role: 'banner', alt: 'Original banner alt')
          seed_branding(role: 'logo', alt: 'Original logo alt', url: 'https://logo.example.com')
          visit "/dashboard/collections/#{collection.id}/edit"
          click_link 'Branding'
        end

        it 'describes branding and shows the banner and logo with their inputs and Remove buttons' do
          within('#branding') do
            expect(page).to have_content('Optionally, you can upload a banner image and/or logo images ' \
                                         'to associate with this collection.')
            within('#banner') do
              expect(page).to have_content('banner.png')
              expect(page).to have_field('banner_text', with: 'Original banner alt')
              expect(page).to have_css('button.branding-banner-remove', text: 'Remove')
            end
            within('#logorow_0') do
              expect(page).to have_content('logo.png')
              expect(page).to have_field('linkurl_0', with: 'https://logo.example.com')
              expect(page).to have_field('alttext_0', with: 'Original logo alt')
              expect(page).to have_css('button.branding-logo-remove', text: 'Remove')
            end
          end
          expect(page).to have_button('Save changes')
          expect(page).to have_link('Cancel', href: "/dashboard/collections/#{collection.id}?locale=en")
        end

        it 'saves the logo Link URL and Alt Text' do
          fill_in 'linkurl_0', with: 'https://new-logo.example.org'
          fill_in 'alttext_0', with: 'Updated logo alt'
          click_button 'Save changes'

          expect(page).to have_content('Collection was successfully updated.')
          expect(branding_for('logo').pluck(:target_url, :alt_text))
            .to eq([['https://new-logo.example.org', 'Updated logo alt']])
          expect(branding_for('banner').count).to eq(1)
        end

        it 'removes the logo with its Remove button' do
          find('#logorow_0 button.branding-logo-remove').click
          expect(page).not_to have_css('#logorow_0')
          click_button 'Save changes'

          expect(page).to have_content('Collection was successfully updated.')
          expect(branding_for('logo')).to be_empty
          expect(branding_for('banner').count).to eq(1)
        end

        it 'removes the banner with its Remove button' do
          find('#banner button.branding-banner-remove').click
          expect(page).not_to have_css('#banner')
          click_button 'Save changes'

          expect(page).to have_content('Collection was successfully updated.')
          expect(branding_for('banner')).to be_empty
          expect(branding_for('logo').count).to eq(1)
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

      it 'explains the discovery options and saves the chosen visibility' do
        click_link 'Discovery'

        within('#discovery') do
          expect(page).to have_content('These settings determine who is able to discover and view ' \
                                       "this collection's landing page")
          expect(page).to have_content('you can still share the collection with specific users and groups ' \
                                       'using the Sharing tab')
          choose 'collection_visibility_open'
        end
        click_button 'Save changes'

        expect(page).to have_content('Collection was successfully updated.')
        expect(Hyrax.query_service.find_by(id: collection.id).visibility).to eq('open')
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

      context 'with users shared as depositor and viewer' do
        let(:depositor) { create(:user, email: 'collection-depositor@example.com') }
        let(:viewer) { create(:user, email: 'collection-viewer@example.com') }
        let(:permission_template) { Hyrax::PermissionTemplate.find_by!(source_id: collection.id.to_s) }

        def grant_for(agent)
          permission_template.access_grants.find_by(agent_type: 'user', agent_id: agent.user_key)
        end

        before do
          permission_template.access_grants.create!(agent_type: 'user', agent_id: depositor.user_key, access: 'deposit')
          permission_template.access_grants.create!(agent_type: 'user', agent_id: viewer.user_key, access: 'view')
          visit "/dashboard/collections/#{collection.id}/edit"
          click_link 'Sharing'
        end

        it 'lists each user under Managers, Depositors and Viewers with Remove buttons plus Save and Cancel' do
          within('table.managers-table') do
            expect(page).to have_css('td', exact_text: user.user_key)
            expect(page).to have_link('Remove')
          end
          within('table.depositors-table') do
            expect(page).to have_css('td', exact_text: depositor.user_key)
            expect(page).not_to have_css('td', exact_text: viewer.user_key)
            expect(page).to have_link('Remove')
          end
          within('table.viewers-table') do
            expect(page).to have_css('td', exact_text: viewer.user_key)
            expect(page).to have_link('Remove')
          end
          expect(page).to have_button('Save changes')
          expect(page).to have_link('Cancel', href: "/dashboard/collections/#{collection.id}?locale=en")
        end

        # Potential duplicate: spec/features/collection_spec.rb:85 (enabled Remove buttons in sharing tables; ci: 'skip' there)
        it 'removes an individual viewer with its Remove button' do
          within(:xpath, "//table[contains(@class,'viewers-table')]//tr[td[normalize-space()='#{viewer.user_key}']]") do
            click_link 'Remove'
          end

          expect(page).not_to have_css('table.viewers-table')
          expect(page).to have_content('No viewers have been added to this collection.')
          expect(grant_for(viewer)).to be_nil
          expect(grant_for(depositor)).to be_present
        end

        # The select2 user search (/users.json) is authorized only for users who can read Users
        # (admins, user_manager, user_reader); a plain collection_manager gets "Loading failed".
        it 'shares the collection with a user through the Add user form' do
          user.add_role(:user_reader, Site.instance)
          other = create(:user, email: 'collection-new-viewer@example.com')
          within('#user-participants-form') { find('a.select2-choice').click }
          within('#select2-drop') do
            find('.select2-input').set(other.user_key)
            find('.select2-result-selectable', text: other.user_key).click
          end
          within('#user-participants-form') do
            select 'Viewer', from: 'permission_template_access_grants_attributes_0_access'
            click_button 'Add'
          end

          within('table.viewers-table') { expect(page).to have_css('td', exact_text: other.user_key) }
          expect(grant_for(other)&.access).to eq('view')
        end
      end
    end
  end

  describe 'Settings -> Collection Types (admin)' do
    let(:user) { create(:admin) }
    let!(:exhibit_type) do
      create(:collection_type, title: 'Exhibit Type', description: 'An exhibit type.',
                               creator_user: user, manager_group: 'admin')
    end

    before { FactoryBot.create(:admin_group) }

    context 'index page' do
      before do
        # The two default types plus the custom Exhibit Type.
        Hyrax::CollectionType.find_or_create_default_collection_type
        Hyrax::CollectionType.find_or_create_admin_set_type
        visit '/admin/collection_types'
      end

      # Potential duplicate: spec/features/collection_type_spec.rb:34 (Edit/Delete buttons per collection type)
      it 'shows the count, Create new collection type button, and edit/delete controls' do
        expect(page).to have_css('.card-header-message', text: '3 collection types in this repository')
        expect(page).to have_link('Create new collection type')
        within('.collection-types-table tbody') do
          expect(page).to have_css('tr', count: 3)
          expect(page).to have_content('Exhibit Type')
          expect(page).to have_link('Edit', count: 3)
          # only the custom (non-default) type gets a Delete button
          expect(page).to have_button('Delete', count: 1)
        end
      end

      it 'expands more information about collection types' do
        expect(page).not_to have_content('Typical scenarios for collection types include')

        find('a.collapse-header[href="#collapseAbout"]').click

        within('#collapseAbout') do
          expect(page).to have_content('Typical scenarios for collection types include')
          expect(page).to have_content('Exhibits that staff create and curate for public display')
        end
      end

      it 'opens a collection type for editing from its Edit button' do
        within(:xpath, "//table[contains(@class,'collection-types-table')]//tr[td[normalize-space()='Exhibit Type']]") do
          click_link 'Edit'
        end

        expect(page).to have_current_path("/admin/collection_types/#{exhibit_type.id}/edit?locale=en")
        expect(page).to have_field('collection_type_title', with: 'Exhibit Type')
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

      it 'returns to the collection types index from Cancel' do
        click_link 'Cancel'
        expect(page).to have_current_path('/admin/collection_types?locale=en')
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

      it 'shows the Description form filled with the type name and description' do
        expect(page).to have_field('collection_type_title', with: 'Exhibit Type')
        expect(page).to have_selector('input#collection_type_title[required]')
        expect(page).to have_field('collection_type_description', with: 'An exhibit type.')
        expect(page).to have_button('Save changes')
        expect(page).to have_link('Cancel', href: %r{/admin/collection_types})
      end

      it 'shows disabled admin-set-only checkboxes on the Settings tab' do
        click_link('Settings', href: '#settings')

        expect(page).to have_unchecked_field('collection_type_require_membership', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_workflow', disabled: true)
        expect(page).to have_unchecked_field('collection_type_assigns_visibility', disabled: true)
      end

      it 'shows the participants add-group/add-user forms and Manager/Creator lists' do
        click_link('Participants', href: '#participants')

        # The "Add Participants" heading sits above the participant forms section.
        expect(page).to have_content('Add Participants')
        within('.section-participants') do
          expect(page).to have_select('collection_type_participant_agent_id')
        end
        # Current Participants: the admin group as manager (shown by its display name) and the
        # creating user as creator, each with a Remove control.
        within('table.managers-table') do
          expect(page).to have_content('Repository Administrators')
          expect(page).to have_link('Remove')
        end
        within('table.creators-table') do
          expect(page).to have_content(user.user_key)
          expect(page).to have_link('Remove')
        end
        expect(page).to have_button('Save changes')
        click_link 'Cancel'
        expect(page).to have_current_path('/admin/collection_types?locale=en')
      end

      def participant(agent)
        Hyrax::CollectionTypeParticipant.find_by(hyrax_collection_type_id: exhibit_type.id, agent_id: agent.user_key)
      end

      # Potential duplicate: spec/features/collection_type_spec.rb:185 (adding a participant via the Participants form)
      it 'adds a user as a manager with the Add user form and removes them again' do
        manager = create(:user, email: 'type-manager@example.com')
        click_link('Participants', href: '#participants')

        within('#user-participants-form') { find('a.select2-choice').click }
        within('#select2-drop') do
          find('.select2-input').set(manager.user_key)
          find('.select2-result-selectable', text: manager.user_key).click
        end
        within('#user-participants-form') do
          select 'Manager', from: 'collection_type_participant_access'
          click_button 'Add'
        end

        expect(page).to have_content('Participants Updated')
        expect(participant(manager)&.access).to eq('manage')

        click_link('Participants', href: '#participants')
        within(:xpath, "//table[contains(@class,'managers-table')]//tr[td[normalize-space()='#{manager.user_key}']]") do
          click_link 'Remove'
        end
        expect(page).to have_content('Participant Removed')
        expect(participant(manager)).to be_nil
      end

      it 'removes an individual creator' do
        click_link('Participants', href: '#participants')

        within(:xpath, "//table[contains(@class,'creators-table')]//tr[td[normalize-space()='#{user.user_key}']]") do
          click_link 'Remove'
        end

        expect(page).to have_content('Participant Removed')
        expect(participant(user)).to be_nil
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
