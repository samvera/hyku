# frozen_string_literal: true

RSpec.describe "proprietor/accounts/edit", type: :view do
  before do
    assign(:account, account)
  end

  context "with connections" do
    let(:account) { create(:account) }

    before do
      allow(Hyrax.config).to receive(:disable_wings).and_return(false)
      render
    end

    it "renders the edit account form including fcrepo fields when Wings is enabled" do
      assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
        assert_select "input#account_tenant[name=?]", "account[tenant]"
        assert_select "input#account_cname[name=?]", "account[cname]"
        assert_select "input#account_fcrepo_endpoint_attributes_url", count: 1
        assert_select "input#account_fcrepo_endpoint_attributes_base_path", count: 1
      end
    end
  end

  context "when Wings is disabled" do
    let(:account) { create(:account) }

    before do
      allow(Hyrax.config).to receive(:disable_wings).and_return(true)
      render
    end

    it "does not render fcrepo endpoint fields" do
      assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
        assert_select "input#account_tenant[name=?]", "account[tenant]"
        assert_select "input#account_cname[name=?]", "account[cname]"
        assert_select "input#account_fcrepo_endpoint_attributes_url", count: 0
        assert_select "input#account_fcrepo_endpoint_attributes_base_path", count: 0
      end
    end
  end

  context "without connections" do
    let(:account) { create(:account, solr_endpoint: nil, fcrepo_endpoint: nil) }

    before do
      allow(Hyrax.config).to receive(:disable_wings).and_return(false)
      render
    end

    it "renders the edit account form" do
      assert_select "form[action=?][method=?]", proprietor_account_path(account), "post" do
        assert_select "input#account_tenant[name=?]", "account[tenant]"
        assert_select "input#account_cname[name=?]", "account[cname]"
        assert_select "input#account_fcrepo_endpoint_attributes_url", count: 1
        assert_select "input#account_fcrepo_endpoint_attributes_base_path", count: 1
      end
    end
  end
end
