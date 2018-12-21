RSpec.describe CatalogController do
  describe "GET /show" do
    let(:file_set) { create(:file_set) }

    context "with access" do
      before do
        sign_in create(:user)
        allow(controller).to receive(:can?).and_return(true)
      end

      it "is successful" do
        get :show, params: { id: file_set }
        expect(response).to be_successful
        expect(response.content_type).to eq 'application/json'
      end
    end

    context "without access" do
      it "is redirects to sign in" do
        get :show, params: { id: file_set }
        expect(response).to redirect_to new_user_session_path
      end
    end
  end
end
