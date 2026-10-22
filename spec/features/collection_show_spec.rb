# frozen_string_literal: true

require 'rails_helper'

# Public collection show page (`hyrax.collection_path`). This is the read-only,
# public-facing view (distinct from the owner dashboard view below). The collection
# and its member work are PUBLIC so an anonymous visitor can reach them, and the same
# expectations run for an anonymous visitor and for an admin.
#
# Hyku is Valkyrie-primary for collections (config.collection_model = 'CollectionResource'),
# so the Valkyrie `:hyku_collection` is the current/supported path. We ALSO run the same
# expectations against a legacy ActiveFedora collection to confirm the lazy migration
# still renders it -- see the note on that context below.
# Manual Test Plan: "Collection Show Page"
RSpec.describe 'Collection show page (public view)', type: :feature, clean: true, flexible: :either do
  let(:admin) { create(:admin) }
  # A public work that matches the member's title words but is NOT in the collection, so
  # a search scoped to the collection must leave it out.
  let!(:non_member_work) do
    FactoryBot.valkyrie_create(:generic_work_resource, visibility_setting: 'open',
                                                       title: ['Outsider Collection member'])
  end

  # Titles of the member works listed on the page, in display order.
  def listed_work_titles
    all('.hyc-bl-results .media-heading a').map(&:text)
  end

  # Content expectations, independent of who is viewing and of the backing.
  shared_examples 'the public collection show page' do
    it 'shows collection metadata, description, and member works' do
      visit hyrax.collection_path(collection.id)

      expect(page).to have_content('Collection show test')
      expect(page).to have_content('Collection description')
      expect(page).to have_content('Collection Details')
      # Only the member work is listed; the matching non-member work is not.
      expect(listed_work_titles).to eq(['Collection member'])
    end

    # The collection's own search form (#collection_search, param `cq`) searches its members;
    # the header search bar would search the whole catalog instead.
    it 'searches within the collection' do
      visit hyrax.collection_path(collection.id)

      fill_in 'collection_search', with: 'Collection member'
      click_button 'collection_submit'

      expect(page).to have_content('Search Results within this Collection')
      expect(listed_work_titles).to eq(['Collection member'])
      expect(page).not_to have_link('Outsider Collection member')
    end
  end

  # Run the content expectations as both an anonymous visitor and an admin.
  shared_examples 'viewable by anonymous and admin visitors' do
    context 'as an anonymous visitor' do
      it_behaves_like 'the public collection show page'
    end

    context 'as an administrator' do
      before { login_as admin, scope: :user }

      it_behaves_like 'the public collection show page'
    end
  end

  context 'with a Valkyrie-backed collection' do
    let!(:collection) do
      FactoryBot.valkyrie_create(:hyku_collection, :public,
                                 title: ['Collection show test'],
                                 description: ['Collection description'])
    end
    # Member-work pattern mirrors collection_editor_role_spec.
    let!(:member_work) do
      FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member,
                                 member_of_collection_ids: [collection.id],
                                 visibility_setting: 'open',
                                 title: ['Collection member'])
    end

    it_behaves_like 'viewable by anonymous and admin visitors'

    def create_member(title)
      FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member,
                                 member_of_collection_ids: [collection.id],
                                 visibility_setting: 'open', title: [title])
    end

    it 'shows the visibility badge, item count, and Last Updated date in the header' do
      visit hyrax.collection_path(collection.id)

      within('.hyc-title') { expect(page).to have_css('.badge', text: 'Public') }
      expect(page).to have_css('.hyc-item-count', text: '1 Item')
      modified = SolrDocument.find(collection.id.to_s).modified_date
      expect(page).to have_css('.hyc-last-updated', text: "Last Updated: #{modified}")
    end

    it 'shows the description next to the representative media' do
      visit hyrax.collection_path(collection.id)

      within('.hyc-body') do
        expect(page).to have_css('img.representative-media[alt="Default representative image"]')
        within('.hyc-metadata') { expect(page).to have_content('Collection description') }
      end
    end

    it 'narrows the member list to the works matching the collection search' do
      create_member('Unrelated volume')
      visit hyrax.collection_path(collection.id)
      expect(listed_work_titles).to contain_exactly('Collection member', 'Unrelated volume')

      fill_in 'collection_search', with: 'Unrelated'
      click_button 'collection_submit'

      expect(page).to have_content('Works (1)')
      expect(listed_work_titles).to eq(['Unrelated volume'])
    end

    it 're-sorts the works with Sort by' do
      # Created in this order, so the newest upload sorts first by Upload Date (Descending),
      # the reverse of the default Title order.
      create_member('Aardvark sorting work')
      create_member('Zebra sorting work')
      visit hyrax.collection_path(collection.id)
      expect(listed_work_titles).to eq(['Aardvark sorting work', 'Collection member', 'Zebra sorting work'])

      select 'Upload Date (Descending)', from: 'sort'
      click_button 'Refresh'

      expect(page).to have_select('sort', selected: 'Upload Date (Descending)')
      expect(listed_work_titles).to eq(['Zebra sorting work', 'Aardvark sorting work', 'Collection member'])
    end

    it 'changes how many works are shown with Results per page' do
      # One more work than a page holds, counting the member created above.
      per_page = Hyrax::CollectionsController.blacklight_config.default_per_page
      per_page.times { |i| create_member(format('Paged work %02d', i)) }
      visit hyrax.collection_path(collection.id)
      expect(page).to have_content("Works (#{per_page + 1})")
      expect(listed_work_titles.size).to eq(per_page)

      select '20', from: 'per_page'
      click_button 'Refresh'

      expect(page).to have_select('per_page', selected: '20')
      expect(listed_work_titles.size).to eq(per_page + 1)
    end

    it 'switches the works layout with the view-type buttons' do
      visit hyrax.collection_path(collection.id)
      expect(page).to have_css('.view-type-group a.view-type-list.active')
      expect(page).to have_css('.hyc-bl-results table')

      within('.view-type-group') { click_link 'Gallery' }

      expect(page).to have_css('.view-type-group a.view-type-gallery.active')
      expect(page).not_to have_css('.view-type-group a.view-type-list.active')
      expect(page).not_to have_css('.hyc-bl-results table')
      expect(page).to have_link('Collection member')
    end
  end

  # LEGACY ActiveFedora collection. Hyku is Valkyrie-primary for collections, and the
  # AF collection factories are the pre-Valkyrie path: Hyku prefixes them `old_` (with a
  # "Work needs to be done to reconcile these two factories" note) and the Hyrax gem's
  # own `:collection` factory is marked "DO NOT ADD tests using this factory". ActiveFedora
  # and Wings are slated for removal from a future Hyrax release in favor of Valkyrie.
  # This context exists only to confirm the lazy migration still renders a legacy AF
  # collection on the public show page; prefer the Valkyrie context above for new tests.
  context 'with an ActiveFedora-backed collection (legacy)' do
    let!(:collection) do
      # The show page looks up the collection's permission template. Creating the template
      # resets the collection's access controls (to restricted), so re-apply public
      # visibility afterwards for the anonymous visitor.
      create(:old_collection, user: admin, with_permission_template: true,
                              title: ['Collection show test'],
                              description: ['Collection description']).tap do |collection|
        collection.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        collection.save!
      end
    end
    let!(:member_work) do
      # Collection membership is recorded on the member work (member_of_collections).
      create(:generic_work, :public, user: admin, title: ['Collection member']).tap do |work|
        work.member_of_collections << collection
        work.save!
      end
    end

    it_behaves_like 'viewable by anonymous and admin visitors'
  end
end

# Owner-facing DASHBOARD collection show page (`/dashboard/collections/:id`).
#
# These examples exercise the owner controls the manual test plan enumerates,
# which only render on the dashboard show page (not the public `hyrax.collection_path`
# view covered above). The owner creates the Valkyrie collection, which gives them a
# permission template with manage access (the :deposit and :manage_items_in_collection
# abilities the nesting/add-items controls need).
#
# The owner holds the collection_manager role: the "Create new collection as subcollection"
# link requires :create_collection_of_type, and when HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS
# is set (as in the dev/test environment) the default User Collection type grants create only
# to admins and the collection_manager/collection_editor roles, not to all registered users.
RSpec.describe 'Dashboard collection show page (owner controls)', type: :feature, clean: true, flexible: :either do
  let(:user) { create(:user, roles: [:collection_manager]) }
  let!(:collection) do
    FactoryBot.valkyrie_create(:hyku_collection,
                               user:,
                               title: ['Owner dashboard collection'],
                               description: ['Owner dashboard description'])
  end
  let!(:member_work) do
    FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member,
                               member_of_collection_ids: [collection.id],
                               visibility_setting: 'open',
                               title: ['Owner dashboard work'])
  end

  before do
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    # Hyku only renders the collection type badge when Site.account is present
    # (Hyrax::CollectionPresenterDecorator#collection_type_badge); it is nil in a
    # single-tenant test run, so supply a tenant account.
    allow(Site).to receive(:account).and_return(create(:account))
    login_as user, scope: :user
    visit "/dashboard/collections/#{collection.id}"
  end

  it 'shows the collection name, visibility, and collection type' do
    within('.collection-title-row-wrapper') do
      expect(page).to have_content('Owner dashboard collection')
      # permission_badge text for a restricted (default) collection
      expect(page).to have_content('Private')
      # collection_type_badge text for the default User Collection type
      expect(page).to have_content('User Collection')
    end
  end

  it 'shows Edit, Add-to, and Delete collection buttons' do
    expect(page).to have_link('Edit collection')
    expect(page).to have_button('Add to collection')
    expect(page).to have_link('Delete collection')
  end

  it "shows the collection's representative media" do
    expect(page).to have_css('.representative-media')
  end

  it 'shows a link to the public view of the collection' do
    expect(page).to have_link('Public view of Collection', href: %r{/collections/#{collection.id}})
  end

  it "shows a table of the collection's metadata" do
    expect(page).to have_css('dl.metadata-collections')
    expect(page).to have_content('Owner dashboard description')
  end

  it 'searches the works within the collection from its search bar' do
    other_work = FactoryBot.valkyrie_create(:generic_work_resource, :as_collection_member,
                                            member_of_collection_ids: [collection.id],
                                            visibility_setting: 'open', title: ['Unrelated dashboard volume'])
    visit "/dashboard/collections/#{collection.id}"
    expect(page).to have_css("tr#document_#{other_work.id}")

    fill_in 'collection_search', with: 'Unrelated'
    click_button 'collection_submit'

    expect(page).to have_css("tr#document_#{other_work.id}", text: 'Unrelated dashboard volume')
    expect(page).not_to have_css("tr#document_#{member_work.id}")
  end

  # Remove this comment and change `xit` back to `it` when issue #3426 is fixed.
  # KNOWN INTERMITTENT FAILURE (CI only, non-flexible mode): Solr dashboard occassionally crashes 
  # with a 500 server errror
  xit 'lists subcollections with buttons to add and create subcollections' do
    expect(page).to have_content('Subcollections (0)')
    # No subcollections have been added yet
    expect(page).to have_content('There are no visible subcollections.')
    # Add an existing collection as a subcollection (opens a modal via JS)
    expect(page).to have_button('Add a subcollection')
    # Create a brand-new collection as a subcollection
    expect(page).to have_link('Create new collection as subcollection')
  end

  it 'lists works with controls to add an existing work and remove a work' do
    expect(page).to have_content('Works (1)')
    expect(page).to have_content('Owner dashboard work')
    # Add an existing work to the collection (navigates to My Works)
    expect(page).to have_link('Add existing works to this collection')
    # Remove an individual work from the collection
    within("tr#document_#{member_work.id}") do
      expect(page).to have_button('Remove')
    end
  end
end

# The "Deposit new work through this collection" control only renders for a user
# who can actually create works. That requires the :work_depositor role plus
# deposit access to an admin set (and a workflow), mirroring the verified setup in
# spec/features/create_generic_work_spec.rb. The owner still gets the
# collection-level abilities via `create_access: true`.
RSpec.describe 'Dashboard collection show page: creating a work through the collection',
               type: :feature, clean: true, flexible: :either do
  let(:user) { create(:user, roles: [:work_depositor]) }
  let!(:collection) do
    create(:collection,
           user:,
           create_access: true,
           title: ['Deposit-through collection'],
           description: ['Deposit-through description'])
  end
  let(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }
  let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
  let(:workflow) do
    Sipity::Workflow.create!(active: true, name: 'test-workflow', permission_template:)
  end

  before do
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    FactoryBot.create(:editors_group) unless Hyrax::Group.exists?(name: 'editors')
    FactoryBot.create(:depositors_group) unless Hyrax::Group.exists?(name: 'depositors')
    Sipity::WorkflowAction.create!(name: 'submit', workflow:)
    Hyrax::PermissionTemplateAccess.create!(
      permission_template_id: permission_template.id,
      agent_type: 'user',
      agent_id: user.user_key,
      access: 'deposit'
    )
    login_as user, scope: :user
    visit "/dashboard/collections/#{collection.id}"
  end

  it 'shows a control to create a work through the collection' do
    expect(page).to have_link('Deposit new work through this collection')
  end
end
