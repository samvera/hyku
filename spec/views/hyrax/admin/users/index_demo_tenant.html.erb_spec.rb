# frozen_string_literal: true

# The invite form on the Manage Users page is hidden from plain admins on
# public demo tenants; tenant superadmins keep it. This lives in its own file
# (rather than index.html.erb_spec.rb) because the tenant flag must be stubbed
# before the first render and the sibling spec renders in a top-level before.
RSpec.describe 'hyrax/admin/users/index.html.erb', type: :view do
  include Devise::Test::ControllerHelpers

  let(:presenter) { Hyrax::Admin::UsersPresenter.new }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(Site).to receive_message_chain(:account, :public_demo_tenant?).and_return(true)
    allow(Site).to receive_message_chain(:account, :search_only?).and_return(false)
    FactoryBot.create(:admin_group, member_users: [current_user])
    sign_in current_user
    @invite_roles_options = ::RolesService::DEFAULT_ROLES
    allow(presenter).to receive(:users).and_return([current_user])
    assign(:presenter, presenter)
    render
  end

  context 'when signed in as a tenant admin' do
    let(:current_user) do
      FactoryBot.create(:user,
                        display_name: 'demo admin',
                        last_sign_in_at: 15.minutes.ago,
                        created_at: 3.days.ago)
    end

    it 'hides the invite form' do
      expect(page).not_to have_selector('div.users-invite')
    end

    it 'still draws the user list' do
      expect(page).to have_selector('div.users-listing')
    end
  end

  context 'when signed in as a tenant superadmin' do
    let(:current_user) do
      FactoryBot.create(:tenant_superadmin,
                        display_name: 'demo superadmin',
                        last_sign_in_at: 15.minutes.ago,
                        created_at: 3.days.ago)
    end

    it 'draws the invite form' do
      expect(page).to have_selector('div.users-invite')
    end
  end
end
