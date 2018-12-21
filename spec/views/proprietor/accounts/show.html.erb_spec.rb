RSpec.describe "proprietor/accounts/show", type: :view do
  let(:account) { FactoryBot.create(:account) }
  let(:admin1) { build(:user) }
  let(:admin2) { build(:user) }

  before do
    allow(Apartment::Tenant).to receive(:switch).with(account.tenant) do |&block|
      block.call
    end
    @account = assign(:account, account)
  end

  it "renders account admin management form" do
    render
    assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
      assert_select "input#add_form_account_admin_emails[name=?]", "account[admin_emails][]"
    end
  end

  it 'has a button to edit account' do
    render
    expect(rendered).to have_css("a[class='btn btn-primary'] span[class='fa fa-edit']")
  end

  context 'with no admin users' do
    before do
      allow(account).to receive(:admin_emails).and_return([])
      render
    end

    it 'displays "No administrators exist"' do
      expect(rendered).to have_content('No administrators exist')
    end
  end

  context 'with admin users' do
    before do
      allow(account).to receive(:admin_emails).and_return([admin1.email, admin2.email])
      render
    end

    it 'displays each user email and a remove button' do
      expect(rendered).to have_content(admin1.email)
      expect(rendered).to have_content(admin2.email)
      expect(rendered).to have_css("input[class='btn btn-danger'][value='Remove']")
    end
  end
end
