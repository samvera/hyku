# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work approval permissions', type: :feature, js: true, clean: true, ci: 'skip' do
  include WorksHelper

  let(:user) { FactoryBot.create(:user) }
  let(:work_creator) { FactoryBot.create(:admin) }
  # These `let!` statements and the following `before` are order-dependent
  let!(:admin_group) { FactoryBot.create(:admin_group) }
  let!(:editors_group) { FactoryBot.create(:editors_group) }
  let!(:depositors_group) { FactoryBot.create(:depositors_group) }
  let!(:admin_set) do
    allow(Hyrax.config).to receive(:default_active_workflow_name).and_return('one_step_mediated_deposit')
    admin_set = AdminSet.new(title: ['Mediated Deposit Admin Set'])
    Hyrax::AdminSetCreateService.call!(admin_set:, creating_user: nil)
  end
  let!(:work) { FactoryBot.valkyrie_create(:generic_work_resource, :with_admin_set, admin_set:, depositor: work_creator.user_key, visibility_setting: 'open') }

  before do
    login_as user
  end

  context 'when signed in as an admin' do
    before do
      admin_group.add_members_by_id([user.id])
    end

    it "can see the workflow actions widget on the work's show page" do
      visit hyrax_generic_work_path(work)

      expect(page).to have_content('Review and Approval')
      expect(page).to have_selector('.workflow-actions')
    end

    it 'can see works submitted for review in the dashboard' do
      visit '/dashboard'
      click_link 'Review Submissions'

      expect(page).to have_content('Review Submissions')
      expect(page).to have_content('Under Review')
      expect(page).to have_content('Published')
      expect(page).to have_content(work.title.first)
    end
  end

  context 'when signed in as a work editor' do
    before do
      editors_group.add_members_by_id([user.id])
    end

    it "can see the workflow actions widget on the work's show page" do
      visit hyrax_generic_work_path(work)

      expect(page).to have_content('Review and Approval')
      expect(page).to have_selector('.workflow-actions')
    end

    it 'can see works submitted for review in the dashboard' do
      visit '/dashboard'
      click_link 'Review Submissions'

      expect(page).to have_content('Review Submissions')
      expect(page).to have_content('Under Review')
      expect(page).to have_content('Published')
      expect(page).to have_content(work.title.first)
    end
  end

  context 'when signed in as a work depositor' do
    before do
      depositors_group.add_members_by_id([user.id])
    end

    it "cannot see the workflow actions widget on the work's show page" do
      visit hyrax_generic_work_path(work)

      expect(page).to have_content(work.title.first) # make sure we're on the show page
      expect(page).not_to have_content('Review and Approval')

      # The CSS selector is there but the contents are empty
      # expect(page).not_to have_selector('.workflow-actions')
    end

    it 'cannot see works submitted for review in the dashboard' do
      visit '/dashboard'
      expect(page).not_to have_link('Review Submissions')
    end
  end

  context 'when signed in as a user with no special access' do
    it "cannot see the workflow actions widget on the work's show page" do
      visit hyrax_generic_work_path(work)

      expect(page).to have_content(work.title.first) # make sure we're on the show page
      expect(page).not_to have_content('Review and Approval')

      # The CSS selector is there but the contents are empty
      # expect(page).not_to have_selector('.workflow-actions')
    end

    it 'cannot see works submitted for review in the dashboard' do
      visit '/dashboard'
      expect(page).not_to have_link('Review Submissions')
    end
  end
end
