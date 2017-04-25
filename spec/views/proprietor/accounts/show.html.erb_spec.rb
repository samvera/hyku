RSpec.describe "proprietor/accounts/show", type: :view do
  let(:account) { FactoryGirl.create(:account) }

  before do
    @account = assign(:account, account)
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to include(account.tenant)
    expect(rendered).to include(account.cname)
  end
end
