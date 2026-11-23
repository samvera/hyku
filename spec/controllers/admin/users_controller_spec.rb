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
        expect(flash[:notice]).to eq "User \"#{user.email}\" has been activated and emailed a link to set their password."
      end

      it 'emails the user a link to set their own password' do
        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq([user.email])
        expect(mail.subject).to eq('Your account has been activated')
        expect(mail.body.encoded).to include('reset_password_token=')
        expect(mail.body.encoded).to include('This link expires in about 6 hours')
        expect(mail.body.encoded).not_to include('ignore this email')
      end

      it 'sends the email in the locale the activation was made in' do
        I18n.with_locale(:de) { post :activate, params: { id: User.invite!(email: 'eingeladen@example.com', skip_invitation: true).id, locale: 'de' } }
        mail = ActionMailer::Base.deliveries.last
        expect(mail.subject).to eq('Ihr Konto wurde aktiviert')
        expect(mail.body.encoded).to include('Mein Passwort festlegen')
      end

      it 'sends one email when Activate is submitted twice' do
        post :activate, params: { id: user.id }
        expect(ActionMailer::Base.deliveries.count { |m| m.subject == 'Your account has been activated' }).to eq(1)
      end

      it 'emails a token that sets a password the user can sign in with' do
        token = ActionMailer::Base.deliveries.last.body.encoded[/reset_password_token=([^"&]+)/, 1]
        User.reset_password_by_token(reset_password_token: token, password: 'Chosen-Passw0rd!', password_confirmation: 'Chosen-Passw0rd!')

        expect(user.reload.valid_password?('Chosen-Passw0rd!')).to be(true)
      end
    end

    describe 'POST #activate for a user who has already accepted' do
      let(:user) { create(:user, password: 'Existing-Passw0rd!', password_confirmation: 'Existing-Passw0rd!') }

      it 'leaves their password alone and reports failure' do
        post :activate, params: { id: user.id }
        expect(user.reload.valid_password?('Existing-Passw0rd!')).to be(true)
        expect(flash[:error]).to eq "User \"#{user.email}\" could not be activated."
      end
    end

    describe 'POST #activate for a user outside this repository' do
      let(:user) { User.invite!(email: 'elsewhere@example.com', skip_invitation: true) }

      before { user.roles.destroy_all }

      it 'does not find them' do
        expect { post :activate, params: { id: user.id } }.to raise_error(ActiveRecord::RecordNotFound)
        expect(user.reload).not_to be_accepted_or_not_invited
      end
    end

    describe 'POST #activate password sourcing' do
      let(:user) { User.invite!(email: 'invited@example.com', skip_invitation: true) }

      before do
        allow(ENV).to receive(:fetch).and_call_original
      end

      context 'when HYKU_USER_DEFAULT_PASSWORD is set' do
        before do
          allow(ENV).to receive(:fetch).with('HYKU_USER_DEFAULT_PASSWORD', nil).and_return('configured-password')
          post :activate, params: { id: user.id }
        end

        it 'assigns the configured password' do
          expect(user.reload.valid_password?('configured-password')).to eq(true)
        end
      end

      context 'when HYKU_USER_DEFAULT_PASSWORD is not set' do
        before do
          allow(ENV).to receive(:fetch).with('HYKU_USER_DEFAULT_PASSWORD', nil).and_return(nil)
          post :activate, params: { id: user.id }
        end

        it 'does not fall back to a hardcoded literal password' do
          expect(user.reload.valid_password?('password')).to eq(false)
        end

        it 'still accepts the invitation' do
          expect(user.reload).to be_accepted_or_not_invited
        end
      end
    end
  end

  context 'as a user_manager (non-admin, admin-delegable role)' do
    let(:user_manager) { FactoryBot.create(:user_manager) }
    let(:victim_admin) { FactoryBot.create(:user, roles: ['admin']) }
    let(:admin_role) { victim_admin.roles.find_by(name: 'admin') }

    before { sign_in user_manager }

    describe 'DELETE #remove_role' do
      it 'does not let a non-admin user_manager strip the admin role from another user' do
        expect do
          delete :remove_role, params: { id: victim_admin.id, role_id: admin_role.id }
        end.not_to change { victim_admin.reload.roles.pluck(:name) }
      end
    end
  end
end
