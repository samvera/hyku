RSpec.describe Proprietor::AccountsController, type: :controller, multitenant: true do
  let(:user) {}

  before do
    sign_in user if user
  end

  # This should return the minimal set of attributes required to create a valid
  # Account. As you add validations to Account, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) do
    { name: 'x' }
  end

  let(:valid_fcrepo_endpoint_attributes) do
    { url: 'http://127.0.0.1:8984/go',
      base_path: '/dev' }
  end

  let(:invalid_attributes) do
    { tenant: 'missing-cname', cname: '' }
  end

  context 'as an anonymous user' do
    describe "GET #new" do
      it "is unauthorized" do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "POST #create" do
      context "with valid params" do
        it "is unauthorized" do
          expect do
            post :create, params: { account: valid_attributes }
          end.not_to change(Account, :count)
          expect(response).to be_redirect
        end
      end
    end
  end

  context 'as an admin of a site' do
    let(:user) { FactoryBot.create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
    let(:account) { FactoryBot.create(:account) }

    before do
      Site.update(account: account)
    end

    describe "GET #index" do
      it "is unauthorized" do
        get :index
        expect(response).to redirect_to root_path
      end
    end

    describe "GET #show" do
      it "assigns the requested account as @account" do
        get :show, params: { id: account.to_param }
        expect(assigns(:account)).to eq(account)
      end
    end

    describe "GET #edit" do
      it "assigns the requested account as @account" do
        get :edit, params: { id: account.to_param }
        expect(assigns(:account)).to eq(account)
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) do
          { cname: 'new.example.com',
            fcrepo_endpoint_attributes: valid_fcrepo_endpoint_attributes,
            admin_emails: ['test@test.com', 'me@myhouse.com'] }
        end

        it "updates the requested account" do
          allow(Apartment::Tenant).to receive(:switch).with(account.tenant) do |&block|
            block.call
          end
          put :update, params: { id: account.to_param, account: new_attributes }
          account.reload
          expect(account.cname).to eq 'new.example.com'
          expect(account.fcrepo_endpoint.url).to eq 'http://127.0.0.1:8984/go'
          expect(account.admin_emails).to match_array(['test@test.com', 'me@myhouse.com'])
          expect(response).to redirect_to([:proprietor, account])
        end

        it "assigns the requested account as @account" do
          put :update, params: { id: account.to_param, account: valid_attributes }
          expect(assigns(:account)).to eq(account)
        end
      end

      context "with invalid params" do
        it "assigns the account as @account" do
          put :update, params: { id: account.to_param, account: invalid_attributes }
          expect(assigns(:account)).to eq(account)
        end

        it "re-renders the 'edit' template" do
          put :update, params: { id: account.to_param, account: invalid_attributes }
          expect(response).to render_template("edit")
        end
      end
    end

    describe "DELETE #destroy" do
      it "denies the request" do
        delete :destroy, params: { id: account.to_param }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'editing another tenants account' do
      let(:another_account) { FactoryBot.create(:account) }

      describe "GET #show" do
        it "denies the request" do
          get :show, params: { id: another_account.to_param }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "GET #edit" do
        it "denies the request" do
          get :edit, params: { id: another_account.to_param }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      describe "PUT #update" do
        it "denies the request" do
          put :update, params: { id: another_account.to_param, account: valid_attributes }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  context 'as a superadmin' do
    let(:user) { FactoryBot.create(:superadmin) }
    let!(:account) { FactoryBot.create(:account) }

    describe "GET #index" do
      it "assigns all accounts as @accounts" do
        get :index
        expect(assigns(:accounts)).to include account
        expect(response).to render_template("layouts/proprietor")
      end
    end

    describe "GET #show" do
      it "assigns the requested account as @account" do
        get :show, params: { id: account.to_param }
        expect(assigns(:account)).to eq(account)
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested account" do
        expect(CleanupAccountJob).to receive(:perform_now).with(account)

        delete :destroy, params: { id: account.to_param }
      end

      it "redirects to the accounts list" do
        expect(CleanupAccountJob).to receive(:perform_now).with(account)
        delete :destroy, params: { id: account.to_param }
        expect(response).to redirect_to(proprietor_accounts_url)
      end
    end
  end

  describe 'account dependency switching' do
    let(:account) { FactoryBot.create(:account) }

    before do
      Site.update(account: account)
      allow(controller).to receive(:current_account).and_return(account)
    end

    it 'switches account information' do
      expect(account).to receive(:switch!)
      get :show, params: { id: account.to_param }
    end
  end
end
