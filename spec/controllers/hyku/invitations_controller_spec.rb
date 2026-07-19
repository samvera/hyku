# frozen_string_literal: true

RSpec.describe Hyku::InvitationsController, type: :controller do
  let(:user) { create(:admin) }

  before do
    sign_in user
    # Recommended by Devise: https://github.com/plataformatec/devise/wiki/How-To:-Test-controllers-with-Rails-3-and-4-%28and-RSpec%29
    # rubocop:disable RSpec/InstanceVariable
    @request.env['devise.mapping'] = Devise.mappings[:user]
    # rubocop:enable RSpec/InstanceVariable
  end

  describe '#after_invite_path_for' do
    it "returns admin_users_path" do
      expect(subject.after_invite_path_for(nil)).to eq Hyrax::Engine.routes.url_helpers.admin_users_path(locale: 'en')
    end
  end

  describe '#create' do
    it 'processes the form' do
      post :create, params: {
        user: {
          email: "user@guest.org",
          role: "manager"
        }
      }
      created_user = User.find_by(email: 'user@guest.org')
      expect(created_user.roles.map(&:name)).to include('manager')
      expect(created_user.roles.map(&:resource_type).uniq).to contain_exactly('Site', 'Hyrax::Group')
      expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.admin_users_path(locale: 'en')
      expect(flash[:notice]).to eq 'An invitation email has been sent to user@guest.org.'
    end

    context 'when user already exists' do
      let(:user) { create(:user) }

      # Mimic the state of a user who is only active in other tenants;
      # i.e. a user who has no roles in this tenant
      before do
        user.roles.destroy_all
      end

      it 'adds the user to the registered group' do
        expect(user.roles).to be_empty
        expect(user.groups).to be_empty

        post :create, params: {
          user: {
            email: user.email,
            role: ''
          }
        }

        user.reload
        expect(user.roles).not_to be_empty
        expect(user.groups).to eq([Ability.registered_group_name])
      end
    end

    context 'on a public demo tenant' do
      before do
        allow(Site).to receive_message_chain(:account, :public_demo_tenant?).and_return(true)
        allow(Site).to receive_message_chain(:account, :search_only?).and_return(false)
      end

      context 'when signed in as a tenant admin' do
        it 'denies the invitation and does not create the user' do
          post :create, params: {
            user: {
              email: 'uninvited@guest.org',
              role: 'user_manager'
            }
          }
          expect(User.find_by(email: 'uninvited@guest.org')).to be_nil
          expect(response).to redirect_to root_path
        end
      end

      context 'when signed in as a tenant superadmin' do
        let(:user) { create(:tenant_superadmin) }

        it 'processes the invitation' do
          post :create, params: {
            user: {
              email: 'invited@guest.org',
              role: 'user_manager'
            }
          }
          created_user = User.find_by(email: 'invited@guest.org')
          expect(created_user.roles.map(&:name)).to include('user_manager')
          expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.admin_users_path(locale: 'en')
        end
      end
    end

    context 'on a standard tenant' do
      before do
        allow(Site).to receive_message_chain(:account, :public_demo_tenant?).and_return(false)
        allow(Site).to receive_message_chain(:account, :search_only?).and_return(false)
      end

      it 'still allows a tenant admin to invite users' do
        post :create, params: {
          user: {
            email: 'welcome@guest.org',
            role: 'user_manager'
          }
        }
        expect(User.find_by(email: 'welcome@guest.org')).to be_present
        expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.admin_users_path(locale: 'en')
      end
    end
  end
end
