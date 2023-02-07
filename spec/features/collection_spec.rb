# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Add Groups with Roles feature test coverage
RSpec.describe 'collection', type: :feature, js: true, clean: true do
  let(:user) { create(:user) }

  let(:collection1) { create(:public_collection_lw, user: user) }
  let(:collection2) { create(:public_collection_lw, user: user) }

  describe 'collection show page' do
    let(:collection) do
      create(
        :public_collection_lw,
        user: user, description: ['collection description'],
        collection_type_settings: :nestable
      )
    end
    let!(:work1) { create(:work, title: ["King Louie"], member_of_collections: [collection], user: user) }
    let!(:work2) { create(:work, title: ["King Kong"], member_of_collections: [collection], user: user) }
    let!(:col1) do
      create(
        :public_collection_lw,
        title: ["Sub-collection 1"],
        member_of_collections: [collection],
        user: user
      )
    end
    let!(:col2) do
      create(
        :public_collection_lw,
        title: ["Sub-collection 2"],
        member_of_collections: [collection],
        user: user
      )
    end

    before do
      login_as user
      visit "/collections/#{collection.id}"
    end

    # TODO: specs runs to completion, but fails somewhere in the `after` callbacks and/or retries itself?
    xit "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content("Collection Details")
      # Should not show title and description a second time
      expect(page).not_to have_css('.metadata-collections', text: collection.title.first)
      expect(page).not_to have_css('.metadata-collections', text: collection.description.first)
      # Should have search results / contents listing
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      expect(page).to have_content(col1.title.first)
      expect(page).to have_content(col2.title.first)
      expect(page).not_to have_css(".pagination")

      click_link "Gallery"
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
    end

    it "hides collection descriptive metadata when searching a collection" do
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      expect(page).to have_content(work1.title.first)
      expect(page).to have_content(work2.title.first)
      fill_in('collection_search', with: work1.title.first)
      click_button('collection_submit')
      # Should not have Collection metadata table (only title and description)
      expect(page).not_to have_content("Total works")
      expect(page).to have_content(collection.title.first)
      expect(page).to have_content(collection.description.first)
      # Should have search results / contents listing
      expect(page).to have_content("Search Results")
      expect(page).to have_content(work1.title.first)
      expect(page).not_to have_content(work2.title.first)
    end

    # NOTE(bkiahstroud): set :js to false to avoid #have_http_status from throwing Capybara::NotSupportedByDriverError
    it "returns json results", js: false do
      visit "/collections/#{collection.id}.json"
      expect(page).to have_http_status(:success)
      json = JSON.parse(page.body)
      expect(json['id']).to eq collection.id
      expect(json['title']).to match_array collection.title
    end

    context "with a non-nestable collection type" do
      let(:collection) do
        build(
          :public_collection_lw,
          user: user,
          description: ['collection description'],
          collection_type_settings: :not_nestable,
          with_solr_document: true, with_permission_template: true
        )
      end

      it "displays basic information on its show page" do
        expect(page).to have_content(collection.title.first)
        expect(page).to have_content(collection.description.first)
        expect(page).to have_content("Collection Details")
      end
    end
  end

  # TODO: this is just like the block above. Merge them.
  describe 'show work pages of a collection' do
    before do
      docs = (0..12).map do |n|
        { "has_model_ssim" => ["GenericWork"], :id => "zs25x871q#{n}",
          "depositor_ssim" => [user.user_key],
          "suppressed_bsi" => false,
          "member_of_collection_ids_ssim" => [collection.id],
          "nesting_collection__parent_ids_ssim" => [collection.id],
          "edit_access_person_ssim" => [user.user_key] }
      end
      ActiveFedora::SolrService.add(docs, commit: true)

      login_as user
    end
    let(:collection) { create(:named_collection_lw, user: user) }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit "/collections/#{collection.id}"
      expect(page).to have_css(".pagination")
    end
  end

  describe 'show subcollection pages of a collection' do
    before do
      docs = (0..12).map do |n|
        { "has_model_ssim" => ["Collection"], :id => "zs25x871q#{n}",
          "depositor_ssim" => [user.user_key],
          "suppressed_bsi" => false,
          "member_of_collection_ids_ssim" => [collection.id],
          "nesting_collection__parent_ids_ssim" => [collection.id],
          "edit_access_person_ssim" => [user.user_key] }
      end
      ActiveFedora::SolrService.add(docs, commit: true)

      login_as user
    end
    let(:collection) { create(:named_collection_lw, user: user) }

    it "shows a collection with a listing of Descriptive Metadata and catalog-style search results" do
      visit "/collections/#{collection.id}"
      expect(page).to have_css(".pagination")
    end
  end

  # OVERRIDE: new (non-hyrax) test cases below

  describe 'default collection sharing', ci: 'skip' do
    let!(:non_role_group) { FactoryBot.create(:group, name: 'town_of_bedrock', humanized_name: 'Town of Bedrock') }
    let(:user) { create(:admin) }

    before do
      create(:role, :collection_manager)
      create(:role, :collection_editor)
      create(:role, :collection_reader)
      FactoryBot.create(:user, email: 'user@example.com')
      login_as user
    end

    context 'when creating a collection' do
      before do
        visit 'dashboard/collections/new'

        fill_in('Title', with: 'Default Sharing Test')
        click_button 'Save'

        click_link 'Sharing'
      end

      it 'excludes default role access_grants from rendering in tables' do
        expect(page.html).not_to include('<td data-agent="collection_manager">collection_manager</td>')
        expect(page.html).not_to include('<td data-agent="collection_editor">collection_editor</td>')
        expect(page.html).not_to include('<td data-agent="collection_reader">collection_reader</td>')
      end

      it 'displays the groups humanized name' do
        expect(page).to have_content 'Add Sharing'
        expect(
          page.has_select?(
            'permission_template_access_grants_attributes_0_agent_id',
            with_options: [non_role_group.humanized_name]
          )
        ).to be true
      end

      # TODO: Skip this test since it consistently fails if we don't `sleep` for
      # an unacceptably long time in each one of them
      xit "includes user access_grants to render in tables" do # rubocop:disable RSpec/ExampleLength
        expect(page).to have_content 'Add Sharing'

        # within the typeahead input the first two characters of the user's
        # email and wait one second for the item to populate in the table
        within('#s2id_permission_template_access_grants_attributes_0_agent_id') do
          fill_in "s2id_autogen2", with: 'us'
          sleep 1
        end

        # check for the existence of the user's email from the typeahead dropdown menu
        within('#select2-drop') do
          within('.select2-results', match: :first) do
            within('.select2-result', match: :first) do
              find('.select2-result-label', text: 'user@example.com').click
            end
          end
        end

        # from the add user form select the value 'Manager' from the dropdown menu and click the 'Add' button
        within('.section-add-sharing') do
          last_container = all('.form-add-sharing-wrapper').last
          within(last_container) do
            select("Manager", from: 'permission_template_access_grants_attributes_0_access')
            click_button('Add')
          end
        end

        # wait ten seconds for the item to populate in the table and check for it's existence
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10
        expect(page).to have_content("The collection's sharing options have been updated.")
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="user@example.com"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td data-agent="user@example.com">user@example.com</td>')
      end

      # TODO: Skip this test since it consistently fails if we don't `sleep` for
      # an unacceptably long time in each one of them
      xit "includes non-role group access_grants to render in tables" do
        expect(page).to have_content 'Add Sharing'

        # select the non-role group, assign role 'Manager', and add it to the collection type
        select("Town of Bedrock", from: 'permission_template_access_grants_attributes_0_agent_id')
        select("Manager", from: 'permission_template_access_grants_attributes_0_access', match: :first)
        within('.section-add-sharing') do
          click_button('Add', match: :first)
        end

        # wait ten seconds for the item to populate in the table and check for it's existence
        # NOTE: This test consistently fails without this line. For reasons currently unknown,
        # the time between clicking the button and the page refreshing
        # with the change is unacceptably long. Hence why we currently skip this spec.
        sleep 10
        expect(page).to have_content("The collection's sharing options have been updated.")
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="town_of_bedrock"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td data-agent="town_of_bedrock">Town Of Bedrock</td>')
      end
    end

    context 'sharing a collection' do
      let!(:collection) { FactoryBot.create(:collection_lw, with_permission_template: true) }
      let(:access) { Hyrax::PermissionTemplateAccess::MANAGE }

      before do
        collection.permission_template.access_grants.find_or_create_by!(
          access: access,
          agent_type: Hyrax::PermissionTemplateAccess::GROUP,
          agent_id: 'admin'
        )

        visit "/dashboard/collections/#{ERB::Util.url_encode(collection.id)}/edit#sharing"
      end

      context 'when the Repository Administrators group is given MANAGE access' do
        let(:access) { Hyrax::PermissionTemplateAccess::MANAGE }

        it 'renders a disabled remove button' do
          manager_row_html = find('table.managers-table')
                             .find(:xpath, '//td[@data-agent="admin"]')
                             .find(:xpath, '..')['innerHTML']
          expect(manager_row_html).to include(
            '<a class="btn btn-sm btn-danger disabled" disabled="disabled" ' \
            'title="The repository administrators group cannot be removed"'
          )
        end
      end

      context 'when the Repository Administrators group is given DEPOSIT access' do
        let(:access) { Hyrax::PermissionTemplateAccess::DEPOSIT }

        it 'renders an enabled remove button' do
          depositor_row_html = find('table.depositors-table')
                               .find(:xpath, '//td[@data-agent="admin"]')
                               .find(:xpath, '..')['innerHTML']
          expect(depositor_row_html).to include('<a class="btn btn-sm btn-danger"')
          expect(depositor_row_html).not_to include(
            '<a class="btn btn-sm btn-danger disabled" disabled="disabled" ' \
            'title="The repository administrators group cannot be removed"'
          )
        end
      end

      context 'when the Repository Administrators group is given VIEW access' do
        let(:access) { Hyrax::PermissionTemplateAccess::VIEW }

        it 'renders an enabled remove button' do
          viewer_row_html = find('table.viewers-table')
                            .find(:xpath, '//td[@data-agent="admin"]')
                            .find(:xpath, '..')['innerHTML']
          expect(viewer_row_html).to include('<a class="btn btn-sm btn-danger"')
          expect(viewer_row_html).not_to include(
            '<a class="btn btn-sm btn-danger disabled" disabled="disabled" ' \
            'title="The repository administrators group cannot be removed"'
          )
        end
      end
    end
  end
end
