# frozen_string_literal: true

# NOTE: If want to run spec in browser, you have to set "js: true"
RSpec.describe 'Creating a new Work', type: :feature, clean: true do
  let(:user) { create(:user, roles: [:work_depositor]) }

  before do
    FactoryBot.create(:registered_group)
    FactoryBot.create(:admin_group)
    FactoryBot.create(:editors_group)
    FactoryBot.create(:depositors_group)
    Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
    login_as user, scope: :user
  end

  it 'creates the work' do
    visit '/'
    click_link "Share Your Work"
    expect(page).to have_button "Create work"
  end

  context 'as a user with no roles' do
    let(:user) { create(:user) }

    it 'cannot see the add new work button' do
      visit '/dashboard/my/works'
      expect(page).not_to have_link "Add New Work"
    end

    context 'who has deposit access for a specific admin set' do
      let(:admin_set_2) do
        create(:hyku_admin_set, title: ["Another Admin Set"],
                                description: ["A description"])
      end

      before do
        create(:permission_template_access,
               :deposit,
               permission_template: create(:permission_template,
                                           source_id: admin_set_2.id,
                                           with_admin_set: true,
                                           with_active_workflow: true),
               agent_type: 'user',
               agent_id: user.user_key)
      end

      it 'can see the add new work button' do
        visit '/dashboard/my/works'
        expect(page).to have_link "Add New Work"
      end
    end

    context 'who belongs to a group with deposit access for a specific admin set' do
      let(:admin_set_3) do
        create(:hyku_admin_set, title: ["Yet Another Admin Set"],
                                description: ["A description"])
      end
      let(:depositors_group) { create(:depositors_group, name: 'deposit', member_users: [user]) }

      before do
        create(:permission_template_access,
               :deposit,
               permission_template: create(:permission_template,
                                           source_id: admin_set_3.id,
                                           with_admin_set: true,
                                           with_active_workflow: true),
               agent_type: 'group',
               agent_id: depositors_group.name)
      end

      it 'can see the add new work button' do
        visit '/dashboard/my/works'
        expect(page).to have_link "Add New Work"
      end
    end
  end
end
