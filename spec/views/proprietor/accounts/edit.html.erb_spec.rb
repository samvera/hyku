RSpec.describe "proprietor/accounts/edit", type: :view do
  let(:account) { FactoryGirl.create(:account) }

  before do
    assign(:account, account)
  end

  it "renders the edit account form" do
    render

    assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
      assert_select "input#account_tenant[name=?]", "account[tenant]"

      assert_select "input#account_cname[name=?]", "account[cname]"
    end
  end
end
