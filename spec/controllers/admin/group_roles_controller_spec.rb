# frozen_string_literal: true

RSpec.describe Admin::GroupRolesController, faketenant: true do
  let(:group) { FactoryBot.create(:group) }

  context 'as an anonymous user' do
    describe 'GET #index' do
      subject { get :index, params: { group_id: group.id } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  context 'as an admin user' do
    before { sign_in create(:admin) }

    describe 'POST #create' do
      let(:role) { FactoryBot.create(:role, :work_editor) }

      it 'attaches a role to a group' do
        expect do
          post :create, params: { group_id: group.id, role_id: role.id }
        end.to change(group.roles, :count).by(1)
      end
    end
  end

  context 'as a low-privilege signed-in user (privilege escalation)' do
    let(:low_priv_user) { FactoryBot.create(:user) }
    let(:bystander) { FactoryBot.create(:user) }
    let(:admin_role) { FactoryBot.create(:role, :admin) }
    # User's after_create callback already put both users in this group; fetch, don't recreate.
    let(:registered_group) { Hyrax::Group.find_by!(name: Ability.registered_group_name) }

    before do
      sign_in low_priv_user
      bystander
    end

    describe 'POST #create' do
      it 'does not let the user attach the admin role to a group' do
        expect do
          post :create, params: { group_id: registered_group.id, role_id: admin_role.id }
        end.not_to change(registered_group.roles, :count)
      end

      it 'does not make every member of the group a tenant admin as a side effect' do
        post :create, params: { group_id: registered_group.id, role_id: admin_role.id }
        expect(Ability.new(bystander.reload).admin?).to be false
      end
    end
  end

  context 'as a user_manager (non-admin, admin-delegable role)' do
    let(:user_manager) { FactoryBot.create(:user_manager) }
    let(:bystander) { FactoryBot.create(:user) }
    let(:admin_role) { FactoryBot.create(:role, :admin) }
    let(:registered_group) { Hyrax::Group.find_by!(name: Ability.registered_group_name) }

    before do
      sign_in user_manager
      bystander
    end

    describe 'POST #create' do
      it 'does not let a user_manager attach the admin role to the registered group' do
        expect do
          post :create, params: { group_id: registered_group.id, role_id: admin_role.id }
        end.not_to change(registered_group.roles, :count)
      end

      it 'does not make every member of the group a tenant admin as a side effect' do
        post :create, params: { group_id: registered_group.id, role_id: admin_role.id }
        expect(Ability.new(bystander.reload).admin?).to be false
      end
    end
  end
end
