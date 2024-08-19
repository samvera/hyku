# frozen_string_literal: true

RSpec.describe Admin::UsersController, type: :controller do
  context 'as an anonymous user' do
    let(:user) { FactoryBot.create(:user) }

    describe 'DELETE #destroy' do
      subject { User.find_by(id: user.id) }

      before { delete :destroy, params: { id: user.id } }

      it "doesn't delete the user and redirects to login" do
        expect(subject).not_to be_nil
        expect(response).to redirect_to root_path
      end
    end
  end

  context 'as an admin user' do
    before do
      sign_in create(:admin)
    end

    describe 'DELETE #destroy' do
      subject { User.find_by(id: user.id) }

      let(:user) { FactoryBot.create(:user) }

      before do
        delete :destroy, params: { id: user.to_param }
      end

      it "deletes the user roles, but does not delete the user and displays success message" do
        expect(subject).not_to be_nil
        Account.from_request('') do
          expect(subject.roles).to be_blank
        end
        expect(flash[:notice]).to eq "User \"#{user.email}\" has been successfully deleted."
      end
    end

    describe 'POST #activate' do
      let(:user) { User.invite!(email: 'invited@example.com', skip_invitation: true) }

      before do
        post :activate, params: { id: user.id }
      end

      it 'accepts the invitation for the user' do
        expect(user).not_to be_accepted_or_not_invited
        user.reload
        expect(user).to be_accepted_or_not_invited
      end

      it 'redirects to the admin users path with a success notice' do
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to eq "User \"#{user.email}\" has been successfully activated."
      end
    end
  end
end
