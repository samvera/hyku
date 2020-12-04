# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'AdminSet form Participants tab', type: :feature, js: true, clean: true do
  include Warden::Test::Helpers

  context 'as an admin user' do
    let(:admin) { FactoryBot.create(:admin) }
    let!(:admin_group) { FactoryBot.create(:admin_group) }
    let!(:registered_group) { FactoryBot.create(:registered_group) }
    let!(:admin_set_id) { AdminSet.find_or_create_default_admin_set_id }
    let!(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id) }
    let!(:workflow) do
      Sipity::Workflow.create!(
        active: true,
        name: 'test-workflow',
        permission_template: permission_template
      )
    end

    before do
      login_as admin
    end

    context 'add group participants' do
      let!(:group) { FactoryBot.create(:group, name: 'dummy') }

      before do
        visit "/admin/admin_sets/#{ERB::Util.url_encode(admin_set_id)}/edit#participants"
      end

      it 'can add a group as a Manager of the admin set' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(all('table.share-status').first).not_to have_content('dummy')
        expect(all('table.share-status').last).not_to have_content('dummy')

        within('form#group-participants-form') do
          find('select#permission_template_access_grants_attributes_0_agent_id option', text: 'dummy').click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Manager').click
          find('input.btn-info').click
        end

        expect(all('table.share-status').first).to have_content('dummy')
        expect(all('table.share-status').last).not_to have_content('dummy')
      end

      it 'can add a group as a Depositor of the admin set' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(all('table.share-status').first).not_to have_content('dummy')
        expect(all('table.share-status').last).not_to have_content('dummy')

        within('form#group-participants-form') do
          find('select#permission_template_access_grants_attributes_0_agent_id option', text: 'dummy').click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Depositor').click
          find('input.btn-info').click
        end

        expect(all('table.share-status').first).not_to have_content('dummy')
        expect(all('table.share-status').last).to have_content('dummy')
      end

      it 'can add a group as a Viewer of the admin set' do
        expect(page).to have_content('Add Participants')
        expect(page).to have_content('Add group')
        expect(all('table.share-status').first).not_to have_content('dummy')
        expect(all('table.share-status').last).not_to have_content('dummy')

        within('form#group-participants-form') do
          find('select#permission_template_access_grants_attributes_0_agent_id option', text: 'dummy').click
          find('select#permission_template_access_grants_attributes_0_access option', text: 'Viewer').click
          find('input.btn-info').click
        end

        expect(all('table.share-status').first).not_to have_content('dummy')
        expect(all('table.share-status').last).to have_content('dummy')
      end
    end
  end
end
