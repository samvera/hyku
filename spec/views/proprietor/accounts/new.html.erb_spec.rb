# frozen_string_literal: true

RSpec.describe "proprietor/accounts/new", type: :view do
  before do
    assign(:account, Account.new(
                       name: "MyString"
                     ))
  end

  it "renders new account form" do
    render

    assert_select "form[action=?][method=?]", proprietor_accounts_path, "post" do
      assert_select "input#account_name[name=?]", "account[name]"
    end
  end
end
