RSpec.describe Admin::GroupUsersController, faketenant: true do
  let(:group) { FactoryGirl.create(:group) }

  context 'as an anonymous user' do
    describe 'GET #index' do
      subject { get :index, params: { group_id: group.id } }
      it { is_expected.to redirect_to root_path }
    end
  end

  context 'as an admin user' do
    before { sign_in create(:admin) }

    describe 'GET #index' do
      subject { get :index, params: { group_id: group.id } }
      it { is_expected.to render_template('layouts/dashboard') }
      it { is_expected.to render_template('admin/groups/users') }
    end

    context 'modifying group membership' do
      let(:user) { FactoryGirl.create(:user) }

      describe 'POST #add' do
        it 'adds a user to a group when it recieves a group ID' do
          expect do
            post :add, params: { group_id: group.id, user_ids: user.id }
          end.to change(group.members, :count).by(1)
        end
      end

      describe 'DELETE #remove' do
        before { group.add_members_by_id(user.id) }

        it 'removes a user from a group when it recieves a group ID' do
          expect do
            delete :remove, params: { group_id: group.id, user_ids: user.id }
          end.to change(group.members, :count).by(-1)
        end
      end
    end
  end
end
