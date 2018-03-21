RSpec.describe "proprietor/accounts/edit", type: :view do
  before do
    assign(:account, account)
    render
  end

  context "with connections" do
    let(:account) { create(:account) }

    it "renders the edit account form" do
      assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
        assert_select "input#account_tenant[name=?]", "account[tenant]"
        assert_select "input#account_cname[name=?]", "account[cname]"
      end
    end
  end

  context "without connections" do
    let(:account) { create(:account, solr_endpoint: nil, fcrepo_endpoint: nil) }

    it "renders the edit account form" do
      assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
        assert_select "input#account_tenant[name=?]", "account[tenant]"
        assert_select "input#account_cname[name=?]", "account[cname]"
      end
    end
  end
end
