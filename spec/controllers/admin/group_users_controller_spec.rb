# frozen_string_literal: true

RSpec.describe Admin::GroupUsersController, faketenant: true do
  let(:group) { FactoryBot.create(:group) }

  context 'as an anonymous user' do
    describe 'GET #index' do
      subject { get :index, params: { group_id: group.id } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  context 'as an admin user' do
    before { sign_in create(:admin) }

    describe 'GET #index' do
      subject { get :index, params: { group_id: group.id } }

      it { is_expected.to render_template('layouts/hyrax/dashboard') }
      it { is_expected.to render_template('admin/groups/users') }
    end

    context 'modifying group membership' do
      let(:user) { FactoryBot.create(:user) }

      describe 'POST #create' do
        it 'adds a user to a group when it recieves a group ID' do
          expect do
            post :create, params: { group_id: group.id, user_id: user.id }
          end.to change(group.members, :count).by(1)
        end
      end

      describe 'DELETE #destroy' do
        before { group.add_members_by_id(user.id) }

        it 'removes a user from a group when it recieves a group ID' do
          expect do
            delete :destroy, params: { group_id: group.id, user_id: user.id }
          end.to change(group.members, :count).by(-1)
        end
      end
    end
  end

  context 'as a low-privilege signed-in user (privilege escalation)' do
    let(:low_priv_user) { FactoryBot.create(:user) }
    let(:admin_group) { FactoryBot.create(:admin_group) }

    before { sign_in low_priv_user }

    describe 'POST #create' do
      it 'does not let the user add themself to the admin group' do
        expect do
          post :create, params: { group_id: admin_group.id, user_id: low_priv_user.id }
        end.not_to change(admin_group.members, :count)
      end

      it 'does not grant admin ability as a side effect of the request' do
        post :create, params: { group_id: admin_group.id, user_id: low_priv_user.id }
        expect(Ability.new(low_priv_user.reload).admin?).to be false
      end
    end

    describe 'DELETE #destroy' do
      let(:other_group) { FactoryBot.create(:group, member_users: [low_priv_user, victim]) }
      let(:victim) { FactoryBot.create(:user) }

      it 'does not let the user remove another member from a group they do not manage' do
        expect do
          delete :destroy, params: { group_id: other_group.id, user_id: victim.id }
        end.not_to change(other_group.members, :count)
      end
    end
  end

  context 'as a user_manager (non-admin, admin-delegable role)' do
    let(:user_manager) { FactoryBot.create(:user_manager) }
    let(:admin_group) { FactoryBot.create(:admin_group) }

    before { sign_in user_manager }

    describe 'POST #create' do
      it 'does not let a user_manager add themself to the admin group' do
        expect do
          post :create, params: { group_id: admin_group.id, user_id: user_manager.id }
        end.not_to change(admin_group.members, :count)
      end

      it 'does not grant admin ability as a side effect of the request' do
        post :create, params: { group_id: admin_group.id, user_id: user_manager.id }
        expect(Ability.new(user_manager.reload).admin?).to be false
      end
    end
  end
end
