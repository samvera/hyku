# frozen_string_literal: true

RSpec.describe "proprietor/accounts/index", type: :view do
  let(:account_a) { FactoryBot.create(:account) }
  let(:account_b) { FactoryBot.create(:account) }

  before do
    assign(:accounts, [account_a, account_b])
  end

  it "renders a list of accounts" do
    render
    assert_select "tr>td", text: account_a.tenant.to_s
    assert_select "tr>td", text: account_a.cname.to_s

    assert_select "tr>td", text: account_b.tenant.to_s
    assert_select "tr>td", text: account_b.cname.to_s
  end
end
