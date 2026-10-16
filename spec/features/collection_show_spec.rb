# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection show page', type: :feature, clean: true do
  let(:user) { create(:user) }
  let!(:collection) do
    create(:collection, user:, title: ['Collection show test'], description: ['Collection description'])
  end
  let!(:work) { create(:generic_work, user:, title: ['Collection member']) }

  before do
    collection.members << work
    collection.save!
  end

  it 'shows collection metadata, description, and member works' do
    visit hyrax_collection_path(collection)

    expect(page).to have_content('Collection show test')
    expect(page).to have_content('Collection description')
    expect(page).to have_content('Collection member')
    expect(page).to have_content('Collection Details')
  end

  it 'searches within the collection' do
    visit hyrax_collection_path(collection)

    expect(page).to have_field('search-field-header')
    fill_in 'search-field-header', with: 'Collection member'
    click_button 'search-submit-header'

    expect(page).to have_content('Collection member')
  end
end

# Owner-facing DASHBOARD collection show page (`/dashboard/collections/:id`).
#
# These examples exercise the owner controls the manual test plan enumerates,
# which only render on the dashboard show page (not the public `hyrax_collection_path`
# view covered above). The collection is built with `create_access: true` so the
# owner receives a permission template granting manage access. That yields the
# :deposit and :manage_items_in_collection abilities (see
# app/models/concerns/hyrax/ability/collection_ability.rb), which the
# nesting/add-items controls require. Because the owner is a registered, non-admin
# user, they also retain :create_collection_of_type (granted to the `registered`
# group on the default User Collection type), which the "Create new collection as
# subcollection" link requires and which admin users do NOT receive.
RSpec.describe 'Dashboard collection show page (owner controls)', type: :feature, clean: true do
  let(:user) { create(:user) }
  let!(:collection) do
    create(:collection,
           user:,
           create_access: true,
           title: ['Owner dashboard collection'],
           description: ['Owner dashboard description'])
  end
  let!(:member_work) do
    create(:generic_work, :public, user:, title: ['Owner dashboard work'])
  end

  before do
    FactoryBot.create(:admin_group) unless Hyrax::Group.exists?(name: 'admin')
    FactoryBot.create(:registered_group) unless Hyrax::Group.exists?(name: 'registered')
    collection.members << member_work
    collection.save!
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
    expect(page).to have_link('Public view of Collection', href: hyrax_collection_path(collection.id))
  end

  it "shows a table of the collection's metadata" do
    expect(page).to have_css('dl.metadata-collections')
    expect(page).to have_content('Owner dashboard description')
  end

  it 'shows a search bar scoped to the collection' do
    expect(page).to have_css('#collection_search')
    expect(page).to have_css('#collection_submit')
  end

  it 'lists subcollections with buttons to add and create subcollections' do
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
               type: :feature, clean: true do
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


# ## Dashboard Collection Show Page
# [Back to TOC](#table-of-contents)

# ![image29](https://github.com/samvera/hyku/assets/19597776/8a75ff01-dc17-4902-a30b-b687e18163aa)

# ### As a user:

# - [ ] I can see the name of my collection, its visibility, and its collection type
# - [ ] I can see buttons to Edit collection, Add to collection, and Delete collection
# - [ ] I can see my collection’s representative media
# - [ ] I can see a link to the public view of the collection
# - [ ] I can see a table of the collection’s metadata
# - [ ] I can see a search bar to search subcollections & works within the collection
# - [ ] I can see a list of all the Subcollections within the collection
#   - [ ] I can see a button to add a collection as a subcollection
#   - [ ] I can see a link to create a new collection as a subcollection
# - [ ] I can see a link with all the Works within the collection
#   - [ ] I can see a button to create a work through the collection
#   - [ ] I can see a link to add an existing work to the collection
#   - [ ] I can see a button to remove an individual work from the collection
