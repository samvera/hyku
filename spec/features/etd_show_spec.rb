# frozen_string_literal: true

require 'rails_helper'

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.describe 'Etd show page', type: :feature, js: true, clean: true, cohort: 'alpha' do
  include Warden::Test::Helpers
  let(:etd) { FactoryBot.create(:etd) }

  before do
    FactoryBot.create(:admin_group)
    FactoryBot.create(:registered_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)

    admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
    permission_template = Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set_id)
    Sipity::Workflow.create!(active: true, name: 'test-workflow', permission_template:)

    login_as FactoryBot.create(:admin)
  end

  describe 'attribute labels' do
    it 'displays the custom Etd labels' do
      visit "/concern/etds/#{etd.id}"
      metadata = find('dl.work-show.etd')

      expect(metadata).to have_content('Date')
      expect(metadata).not_to have_content('Date created')

      expect(metadata).to have_content('Type')
      expect(metadata).not_to have_content('Resource type')

      expect(metadata).to have_content('Rights')
      expect(metadata).not_to have_content('Rights statement')

      expect(metadata).to have_content('Format')

      expect(metadata).to have_content('Degree')
      expect(metadata).not_to have_content('Degree name')

      expect(metadata).to have_content('Level')
      expect(metadata).not_to have_content('Degree level')

      expect(metadata).to have_content('Discipline')
      expect(metadata).not_to have_content('Degree discipline')

      expect(metadata).to have_content('Grantor')
      expect(metadata).not_to have_content('Degree grantor')

      expect(metadata).to have_content('Advisor')

      expect(metadata).to have_content('Committee member')

      expect(metadata).to have_content('Department')
    end
  end
end
