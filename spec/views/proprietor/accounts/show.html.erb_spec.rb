# frozen_string_literal: true

RSpec.describe "proprietor/accounts/show", type: :view do
  let(:account) { FactoryBot.create(:account) }
  let(:superadmin1) { FactoryBot.create(:superadmin, email: 'superadmin_1@example.com') }
  let(:superadmin2) { FactoryBot.create(:superadmin, email: 'superadmin_2@example.com') }

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

    it 'displays "No administrators message"' do
      expect(rendered).to have_content('There are currently no admins assigned to this tenant. Please add some.')
    end
  end

  context 'with admin users' do
    before do
      allow(account).to receive(:admin_emails).and_return([superadmin1.email, superadmin2.email])
      render
    end

    it 'displays each admin email' do
      expect(rendered).to match(/superadmin_1@example.com/)
      expect(rendered).to match(/superadmin_2@example.com/)
    end
  end
end
