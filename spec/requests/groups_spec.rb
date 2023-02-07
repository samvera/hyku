# frozen_string_literal: true

RSpec.describe "Groups", type: :request, singletenant: true, clean: true do
  let!(:user) { FactoryBot.create(:admin) }
  let!(:managers_group) { FactoryBot.create(:admin_group, roles: ['admin', 'dinosaur'], member_users: [user]) }

  context 'within a tenant' do
    context 'an admin user' do
      before do
        login_as(user)
      end

      it 'cannot destroy any user in the Managers group' do
        expect { delete "/admin/groups/#{managers_group.id}/users/#{user.id}" }
          .to change(managers_group.members, :count).by(0)
        expect(response).to have_http_status(:redirect)
        expect(managers_group.members.include?(user)).to eq true
        expect(flash[:error]).to eq "Admin users cannot be removed from this group"
      end

      it 'cannot destroy an admin role in the Managers group' do
        admin_role = managers_group.roles.find_by(name: 'admin')

        expect { delete "/admin/groups/#{managers_group.id}/roles/#{admin_role.id}" }
          .to change(managers_group.roles, :count).by(0)
        expect(response).to have_http_status(:redirect)
        expect(managers_group.roles.include?(admin_role)).to eq true
        expect(flash[:error]).to eq "Admin role cannot be removed from this group"
      end

      it 'can destroy a non-admin role in the Managers group' do
        dinosaur_role = managers_group.roles.find_by(name: 'dinosaur')

        expect { delete "/admin/groups/#{managers_group.id}/roles/#{dinosaur_role.id}" }
          .to change(managers_group.roles, :count).by(-1)
        expect(response).to have_http_status(:redirect)
        expect(managers_group.roles.include?(dinosaur_role)).to eq false
        expect(flash[:notice]).to eq 'Role has successfully been removed from Group'
      end
    end
  end
end
