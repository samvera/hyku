# frozen_string_literal: true

RSpec.describe "account_sign_up/new", type: :view do
  before do
    assign(:account, Account.new(
                       name: "MyString"
                     ))
  end

  it "renders new account form" do
    render

    assert_select "form[action=?][method=?]", account_sign_up_path, "post" do
      assert_select "input#account_name[name=?]", "account[name]"
    end
  end
end
