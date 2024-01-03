# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'actions permitted by the collection_reader role', type: :feature, js: true, clean: true, ci: 'skip' do # rubocop:disable Layout/LineLength
  let!(:role) { FactoryBot.create(:role, :collection_reader) }
  let!(:collection) { FactoryBot.create(:private_collection_lw, with_permission_template: true) }
  let(:user) { FactoryBot.create(:user) }

  context 'a User that has the collection_reader role' do
    before do
      user.add_role(role.name, Site.instance)
      login_as user
    end

    it 'cannot create a Collection' do
      visit '/dashboard/collections/new'

      expect(page).to have_content('You are not authorized to access this page.')
    end

    it 'can view all Collections' do
      visit '/dashboard/collections'
      expect(find('table#collections-list-table'))
        .to have_selector(:id, "document_#{collection.id}")
    end

    it 'can view an individual Collection' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot edit or update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(page).to have_content('You do not have sufficient privileges to edit this document')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L463-L476
    it 'cannot destroy an individual Collection from the Dashboard index view' do
      visit '/dashboard/collections'

      expect(page).to have_content(collection.title.first)
      check_tr_data_attributes(collection.id, 'collection')
      within("#document_#{collection.id}") do
        first('button.dropdown-toggle').click
        first('.itemtrash').click
      end

      # Exepct the modal to be shown that explains why the user can't delete the collection.
      expect(page).to have_selector('div#collection-to-delete-deny-modal', visible: true)
      within('div#collection-to-delete-deny-modal') do
        click_button('Close')
      end
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot destroy batches of Collections from the Dashboard index view' do
      visit '/dashboard/collections'

      expect(find('tr#document_' + collection.id).first('input[type=checkbox]'))
        .to be_disabled
    end

    it 'cannot destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).not_to have_content('Delete collection')
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing subcollections' do
      it 'cannot add an existing collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add a subcollection')
      end

      it 'cannot create a new collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add new collection to this Collection')
      end

      it "cannot remove a subcollection from the parent collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content(sub_col.title.first)
        expect(find("li[data-id='#{sub_col.id}']")).not_to have_content('Remove')
      end

      it "cannot remove a subcollection from the child collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{sub_col.id}"
        expect(page).to have_content(collection.title.first)
        expect(find("li[data-parent-id='#{collection.id}']")).not_to have_content('Remove')
      end
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing works' do
      it 'cannot add an existing work to a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add existing works to this collection')
      end

      it 'cannot deposit a new work through a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Deposit new work through this collection')
      end

      it 'cannot remove any works from a collection' do
        public_work = FactoryBot.create(:work, member_of_collections: [collection], visibility: 'open')
        institutional_work = FactoryBot.create(:work, member_of_collections: [collection], visibility: 'authenticated')
        private_work = FactoryBot.create(:work, member_of_collections: [collection], visibility: 'restricted')
        expect(collection.member_work_ids).to contain_exactly(public_work.id, institutional_work.id, private_work.id)

        visit "/dashboard/collections/#{collection.id}"
        expect(find("tr#document_#{public_work.id}")).not_to have_content('Remove')
        expect(find("tr#document_#{institutional_work.id}")).not_to have_content('Remove')
        expect(page).not_to have_selector("tr#document_#{private_work.id}")
      end
    end
  end

  context 'a User in a Hyrax::Group that has the collection_reader role' do
    let(:hyrax_group) { FactoryBot.create(:group, name: 'collection_reader_group') }

    before do
      hyrax_group.roles << role
      hyrax_group.add_members_by_id(user.id)
      login_as user
    end

    it 'cannot create a Collection' do
      visit '/dashboard/collections/new'

      expect(page).to have_content('You are not authorized to access this page.')
    end

    it 'can view all Collections' do
      visit '/dashboard/collections'
      expect(find('table#collections-list-table'))
        .to have_selector(:id, "document_#{collection.id}")
    end

    it 'can view an individual Collection' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot edit or update a Collection' do
      visit "/dashboard/collections/#{collection.id}/edit"
      expect(page).to have_content('You do not have sufficient privileges to edit this document')
    end

    # This test is heavily inspired by a test in Hyrax v2.9.0, see
    # https://github.com/samvera/hyrax/blob/v2.9.0/spec/features/dashboard/collection_spec.rb#L463-L476
    it 'cannot destroy a Collection from the Dashboard index view' do
      visit '/dashboard/collections'

      expect(page).to have_content(collection.title.first)
      check_tr_data_attributes(collection.id, 'collection')
      within("#document_#{collection.id}") do
        first('button.dropdown-toggle').click
        first('.itemtrash').click
      end

      # Exepct the modal to be shown that explains why the user can't delete the collection.
      expect(page).to have_selector('div#collection-to-delete-deny-modal', visible: true)
      within('div#collection-to-delete-deny-modal') do
        click_button('Close')
      end
      expect(page).to have_content(collection.title.first)
    end

    it 'cannot destroy a Collection from the Dashboard show view' do
      visit "/dashboard/collections/#{collection.id}"
      expect(page).not_to have_content('Delete collection')
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing subcollections' do
      it 'cannot add an existing collection as a subcollection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add a subcollection')
      end

      it 'cannot create a new collection as a subcolleciton' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add new collection to this Collection')
      end

      it "cannot remove a subcollection from the parent collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{collection.id}"
        expect(page).to have_content(sub_col.title.first)
        expect(find("li[data-id='#{sub_col.id}']")).not_to have_content('Remove')
      end

      it "cannot remove a subcollection from the child collection's show page" do
        sub_col = FactoryBot.create(
          :private_collection_lw,
          with_permission_template: true,
          member_of_collections: [collection]
        )
        expect(collection.reload.member_collection_ids.count).to eq(1)

        visit "/dashboard/collections/#{sub_col.id}"
        expect(page).to have_content(collection.title.first)
        expect(find("li[data-parent-id='#{collection.id}']")).not_to have_content('Remove')
      end
    end

    # Tests custom :manage_items_in_collection ability
    describe 'managing works' do
      it 'cannot add an existing work to a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Add existing works to this collection')
      end

      it 'cannot deposit a new work through a collection' do
        visit "/dashboard/collections/#{collection.id}"
        expect(page).not_to have_content('Deposit new work through this collection')
      end

      it 'cannot remove any works from a collection' do
        public_work = FactoryBot.create(:work, member_of_collections: [collection], visibility: 'open')
        institutional_work = FactoryBot.create(:work, member_of_collections: [collection], visibility: 'authenticated')
        private_work = FactoryBot.create(:work, member_of_collections: [collection], visibility: 'restricted')
        expect(collection.member_work_ids).to contain_exactly(public_work.id, institutional_work.id, private_work.id)

        visit "/dashboard/collections/#{collection.id}"
        expect(find("tr#document_#{public_work.id}")).not_to have_content('Remove')
        expect(find("tr#document_#{institutional_work.id}")).not_to have_content('Remove')
        expect(page).not_to have_selector("tr#document_#{private_work.id}")
      end
    end
  end

  # NOTE: Helper methods from Hyrax v2.9.0 spec/features/dashboard/collection_spec.rb

  # check table row has appropriate data attributes added
  def check_tr_data_attributes(id, type)
    url_fragment = get_url_fragment(type)
    expect(page).to have_selector("tr[data-id='#{id}'][data-colls-hash]")
    expect(page).to have_selector("tr[data-post-url='/dashboard/collections/#{id}/within?locale=en']")
    expect(page).to have_selector("tr[data-post-delete-url='/#{url_fragment}/#{id}?locale=en']")
  end

  # check data attributes have been transferred from table row to the modal
  def check_modal_data_attributes(id, type)
    url_fragment = get_url_fragment(type)
    expect(page).to have_selector("div[data-id='#{id}']")
    expect(page).to have_selector("div[data-post-delete-url='/#{url_fragment}/#{id}?locale=en']")
  end

  def get_url_fragment(type)
    (type == 'admin_set' ? 'admin/admin_sets' : 'dashboard/collections')
  end
end
