# frozen_string_literal: true

# Augment the v5.0.0 tests to account for Hyku specific scenarios
RSpec.describe 'collection', type: :feature, js: true, clean: true do
  let(:user) { create(:user) }
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

        # Make sure you have filled out all of the required attributes:
        fill_in('collection_title', with: 'Default Sharing Test')
        fill_in('collection_creator', with: 'Somebody Special')
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
    end

    context 'sharing a collection' do
      let(:collection) { FactoryBot.valkyrie_create(:hyku_collection, with_permission_template: true) }
      let(:permission_template) { collection.permission_template }
      let(:access) { Hyrax::PermissionTemplateAccess::MANAGE }

      let(:access_grant) do
        permission_template.access_grants.find_or_create_by!(
          access:,
          agent_type: Hyrax::PermissionTemplateAccess::GROUP,
          agent_id: 'admin'
        )
      end

      before do
        access_grant

        visit "/dashboard/collections/#{ERB::Util.url_encode(collection.id)}/edit#sharing"
      end

      context 'when the Repository Administrators group is given MANAGE access' do
        let(:access) { Hyrax::PermissionTemplateAccess::MANAGE }

        it 'renders a disabled remove button' do
          manager_row = find(:css, 'table.managers-table td[data-agent="admin"]')
                        .find(:xpath, '..')
          delete_access_grant_link = manager_row.find(:css, "a.btn.btn-danger.disabled[data-method=delete]")

          expect(delete_access_grant_link['DISABLED']).to be_present
          expect(delete_access_grant_link["HREF"]).to match(%r{/admin/permission_template_accesses/#{access_grant.id}})
        end
      end

      context 'when the Repository Administrators group is given DEPOSIT access' do
        let(:access) { Hyrax::PermissionTemplateAccess::DEPOSIT }

        it 'renders an enabled remove button' do
          depositors_row = find(:css, 'table.depositors-table td[data-agent="admin"]')
                           .find(:xpath, '..')
          delete_access_grant_link = depositors_row.find(:css, "a.btn.btn-danger[data-method=delete]")

          expect(delete_access_grant_link["HREF"]).to match(%r{/admin/permission_template_accesses/#{access_grant.id}})
        end
      end

      context 'when the Repository Administrators group is given VIEW access' do
        let(:access) { Hyrax::PermissionTemplateAccess::VIEW }

        it 'renders an enabled remove button' do
          # Would be nice if the data-agent were on the TR instead of the TD, but such is the way of
          # things.
          viewer_row = find(:css, 'table.viewers-table td[data-agent="admin"]')
                       .find(:xpath, '..')
          delete_access_grant_link = viewer_row.find(:css, "a.btn.btn-danger[data-method=delete]")
          expect(delete_access_grant_link["HREF"]).to match(%r{/admin/permission_template_accesses/#{access_grant.id}})
        end
      end
    end
  end
end
