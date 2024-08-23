# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminSet form Participants tab', type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'as an admin user' do
    # `before`s and `let!`s are order-dependent -- do not move this `before` from the top
    before do
      FactoryBot.create(:admin_group)
      FactoryBot.create(:registered_group)
      FactoryBot.create(:editors_group)
      FactoryBot.create(:depositors_group)

      Sipity::Workflow.create!(
        active: true,
        name: 'test-workflow',
        permission_template:
      )

      login_as admin
    end

    let(:admin) { FactoryBot.create(:admin) }
    let!(:admin_set_id) { Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id }
    let!(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }

    context 'add group participants' do
      let!(:group) { FactoryBot.create(:group) }

      before do
        visit "/admin/admin_sets/#{ERB::Util.url_encode(admin_set_id)}/edit#participants"
      end

      it 'displays the groups humanized name' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(find('table.managers-table')).not_to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.depositors-table')
        expect(page).not_to have_selector('table.viewers-table')

        expect(
          page.has_select?(
            'permission_template_access_grants_attributes_0_agent_id',
            with_options: [group.humanized_name]
          )
        ).to be true
      end

      it 'can add a group as a Manager of the admin set' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(find('table.managers-table')).not_to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.depositors-table')
        expect(page).not_to have_selector('table.viewers-table')

        within('form#group-participants-form') do
          find(
            'select#permission_template_access_grants_attributes_0_agent_id option',
            text: group.humanized_name
          ).click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Manager').click
          find('input.btn-secondary').click
        end

        expect(find('table.managers-table')).to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.depositors-table')
        expect(page).not_to have_selector('table.viewers-table')
      end

      it 'can add a group as a Depositor of the admin set' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(find('table.managers-table')).not_to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.depositors-table')
        expect(page).not_to have_selector('table.viewers-table')

        within('form#group-participants-form') do
          find(
            'select#permission_template_access_grants_attributes_0_agent_id option',
            text: group.humanized_name
          ).click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Depositor').click
          find('input.btn-secondary').click
        end

        expect(find('table.managers-table')).not_to have_content(group.name.titleize)
        expect(find('table.depositors-table')).to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.viewers-table')
      end

      it 'can add a group as a Viewer of the admin set' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(find('table.managers-table')).not_to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.depositors-table')
        expect(page).not_to have_selector('table.viewers-table')

        within('form#group-participants-form') do
          find(
            'select#permission_template_access_grants_attributes_0_agent_id option',
            text: group.humanized_name
          ).click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Viewer').click
          find('input.btn-secondary').click
        end

        expect(find('table.managers-table')).not_to have_content(group.name.titleize)
        # group does not have access if the table does not render
        expect(page).not_to have_selector('table.depositors-table')
        expect(find('table.viewers-table')).to have_content(group.name.titleize)
      end
    end

    context 'remove a group participant' do
      before do
        visit "/admin/admin_sets/#{ERB::Util.url_encode(admin_set_id)}/edit#participants"
      end

      it 'displays the agent_type in title case' do
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="admin"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td>Group</td>')
      end

      it 'shows a disabled remove button next to Repository Administrator group as a Manager' do
        manager_row_html = find('table.managers-table')
                           .find(:xpath, '//td[@data-agent="admin"]')
                           .find(:xpath, '..')['innerHTML']
        expect(manager_row_html).to include('<td data-agent="admin">Repository Administrators</td>')
        # rubocop:disable Layout/LineLength
        expect(manager_row_html).to include('<input class="btn btn-sm btn-danger disabled" disabled="disabled" title="The repository administrators group cannot be removed" type="submit" value="Remove">')
        # rubocop:enable Metrics/MethodLength
      end

      it 'shows an enabled remove button next to Repository Administrator group as a Depositor' do
        within('form#group-participants-form') do
          find(
            'select#permission_template_access_grants_attributes_0_agent_id option',
            text: "Repository Administrators"
          ).click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Depositor').click
          find('input.btn-secondary').click
        end

        depositor_row_html = find('table.depositors-table')
                             .find(:xpath, './/td[@data-agent="admin"]')
                             .find(:xpath, '..')['innerHTML']
        expect(depositor_row_html).to include('<td data-agent="admin">Repository Administrators</td>')
        expect(depositor_row_html).to include('<input class="btn btn-sm btn-danger" type="submit" value="Remove">')
      end

      it 'shows an enabled remove button next to Repository Administrator group as a Viewer' do
        within('form#group-participants-form') do
          find(
            'select#permission_template_access_grants_attributes_0_agent_id option',
            text: "Repository Administrators"
          ).click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Viewer').click
          find('input.btn-secondary').click
        end

        viewer_row_html = find('table.viewers-table')
                          .find(:xpath, './/td[@data-agent="admin"]')
                          .find(:xpath, '..')['innerHTML']
        expect(viewer_row_html).to include('<td data-agent="admin">Repository Administrators</td>')
        expect(viewer_row_html).to include('<input class="btn btn-sm btn-danger" type="submit" value="Remove">')
      end
    end
  end
end
