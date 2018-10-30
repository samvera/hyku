RSpec.describe Admin::AccountsController, type: :controller do
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

  let(:invalid_attributes) do
    { tenant: 'missing-cname', cname: '' }
  end

  context 'as an admin of a site' do
    let(:user) { FactoryBot.create(:user).tap { |u| u.add_role(:admin, Site.instance) } }
    let(:account) { FactoryBot.create(:account) }

    before do
      Site.update(account: account)
    end

    describe "GET #edit" do
      it "assigns the requested account as @account" do
        get :edit
        expect(assigns(:account)).to eq(account)
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) do
          { cname: 'new.example.com' }
        end

        it "updates the requested account" do
          put :update, params: { account: new_attributes }
          account.reload
          expect(account.cname).to eq 'new.example.com'
          expect(response).to redirect_to(edit_admin_account_path)
        end

        it "assigns the requested account as @account" do
          put :update, params: { account: valid_attributes }
          expect(assigns(:account)).to eq(account)
        end
      end

      context "with invalid params" do
        it "assigns the account as @account" do
          put :update, params: { account: invalid_attributes }
          expect(assigns(:account)).to eq(account)
        end

        it "re-renders the 'edit' template" do
          put :update, params: { account: invalid_attributes }
          expect(response).to render_template("edit")
        end
      end
    end
  end
end
