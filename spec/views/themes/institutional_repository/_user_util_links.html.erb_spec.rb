# frozen_string_literal: true

RSpec.describe 'themes/institutional_repository/_user_util_links.html.erb', type: :view do
  let(:user) { create(:user) }
  let!(:test_strategy) { Flipflop::FeatureSet.current.test! }
  let(:admin_ability) { double(user_groups: ['admin']) }
  let(:user_ability) { double(user_groups: []) }

  after { test_strategy.switch!(:show_login_link, true) }

  context 'when feature flipper is on' do
    before { test_strategy.switch!(:show_login_link, true) }

    describe 'logged in user' do
      before do
        allow(view).to receive(:user_signed_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(user)
        allow(view).to receive(:current_ability).and_return(user_ability)
        render
      end

      it 'shows the links' do
        expect(rendered).to have_link 'Change password', href: edit_user_registration_path
        expect(rendered).to have_link 'Logout', href: destroy_user_session_path
        expect(rendered).to have_link 'Dashboard', href: hyrax.dashboard_path
      end
    end

    describe 'logged in admin user' do
      before do
        allow(view).to receive(:user_signed_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(user)
        allow(view).to receive(:current_ability).and_return(admin_ability)
        render
      end

      it 'shows the links' do
        expect(rendered).to have_link 'Change password', href: edit_user_registration_path
        expect(rendered).to have_link 'Logout', href: destroy_user_session_path
        expect(rendered).to have_link 'Dashboard', href: hyrax.dashboard_path
      end
    end

    describe 'logged out user' do
      before do
        allow(view).to receive(:user_signed_in?).and_return(false)
        allow(view).to receive(:current_user).and_return(nil)
        allow(view).to receive(:current_ability).and_return(nil)
        render
      end

      it 'links to login path' do
        expect(rendered).to have_link 'Login', href: single_signon_index_path
      end
    end
  end

  context 'When feature flipper is off' do
    before { test_strategy.switch!(:show_login_link, false) }

    describe 'logged in user' do
      before do
        allow(view).to receive(:user_signed_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(user)
        allow(view).to receive(:current_ability).and_return(user_ability)
        render
      end

      it 'hides the links' do
        expect(rendered).not_to have_link 'Change password', href: edit_user_registration_path
        expect(rendered).not_to have_link 'Logout', href: destroy_user_session_path
        expect(rendered).to have_link 'Dashboard', href: hyrax.dashboard_path
      end
    end

    describe 'logged in admin user' do
      before do
        allow(view).to receive(:user_signed_in?).and_return(true)
        allow(view).to receive(:current_user).and_return(user)
        allow(view).to receive(:current_ability).and_return(admin_ability)
        render
      end

      it 'shows the links' do
        expect(rendered).to have_link 'Change password', href: edit_user_registration_path
        expect(rendered).to have_link 'Logout', href: destroy_user_session_path
        expect(rendered).to have_link 'Dashboard', href: hyrax.dashboard_path
      end
    end

    describe 'logged out user' do
      before do
        allow(view).to receive(:user_signed_in?).and_return(false)
        allow(view).to receive(:current_user).and_return(nil)
        allow(view).to receive(:current_ability).and_return(nil)
        render
      end

      it 'hides the login path' do
        expect(rendered).not_to have_link 'Login', href: single_signon_index_path
      end
    end
  end
end
