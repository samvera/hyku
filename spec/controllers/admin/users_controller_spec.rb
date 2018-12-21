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
    let(:user) { FactoryBot.create(:user) }

    before { sign_in create(:admin) }

    describe 'DELETE #destroy' do
      subject { User.find_by(id: user.id) }

      before { delete :destroy, params: { id: user.to_param } }

      it "deletes the user and displays success message" do
        expect(subject).to be_nil
        expect(flash[:notice]).to eq "User \"#{user.email}\" has been successfully deleted."
      end
    end
  end
end
