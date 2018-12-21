require "spec_helper"

RSpec.describe "splash/index.html.erb", type: :view do
  let(:page) { Capybara::Node::Simple.new(rendered) }

  context 'Anonymous or non-Admin user with admin_only_tenant_creation=false' do
    before do
      allow(Settings.multitenancy).to receive(:admin_only_tenant_creation).and_return(false)
      allow(controller).to receive(:can?).with(:manage, Account).and_return(false)
      render
    end

    it "displays a 'Get Started' button" do
      expect(page).to have_selector('a.btn-sign-up', text: 'Get Started')
      assert_select "a.btn-sign-up[href=?]", account_sign_up_path
    end
  end

  context 'Admin user with admin_only_tenant_creation=true' do
    before do
      allow(Settings.multitenancy).to receive(:admin_only_tenant_creation).and_return(true)
      allow(controller).to receive(:can?).with(:manage, Account).and_return(true)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      render
    end

    it "displays a 'Get Started' button" do
      expect(page).to have_selector('a.btn-sign-up', text: 'Get Started')
      assert_select "a.btn-sign-up[href=?]", account_sign_up_path
    end
  end

  context 'Anonymous user with admin_only_tenant_creation=true' do
    before do
      allow(Settings.multitenancy).to receive(:admin_only_tenant_creation).and_return(true)
      allow(controller).to receive(:can?).with(:manage, Account).and_return(false)
      allow(controller).to receive(:user_signed_in?).and_return(false)
      render
    end

    it "displays a 'Login to get started' button" do
      expect(page).to have_selector('a.btn-sign-up', text: 'Login to get started')
      assert_select "a.btn-sign-up[href=?]", main_app.new_user_session_path
    end
  end

  context 'Authenticated, non-Admin user with admin_only_tenant_creation=true' do
    before do
      allow(Settings.multitenancy).to receive(:admin_only_tenant_creation).and_return(true)
      allow(controller).to receive(:can?).with(:manage, Account).and_return(false)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      render
    end

    it "displays a 'You are not authorized to create tenants' message" do
      expect(page).to have_no_selector('a.btn-sign-up')
      expect(page).to have_selector('p', text: 'You are not authorized to create tenants')
    end
  end
end
