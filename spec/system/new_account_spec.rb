# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Proprietor New Account Page', type: :system do
  let(:user) { FactoryBot.create(:admin) }
  let(:full_account) { create(:account) }
  let!(:account) { create(:account, search_only: true) }

  before do
    driven_by(:rack_test)
    login_as(user, scope: :user)
    Capybara.default_host = "http://#{account.cname}"
  end

  describe 'shared search checkbox' do
    xit 'can display checkbox for shared_search' do
      visit '/proprietor/accounts/new?locale=en'
      expect(page).to have_content('Search only')
      expect(find_field(id: 'account_search_only')).not_to be_checked
    end

    xit 'can check shared_search checkbox' do
      visit '/proprietor/accounts/new?locale=en'
      check 'account_search_only'
      expect(find_field(id: 'account_search_only')).to be_checked
    end

    xit 'can display add to account text' do
      visit '/proprietor/accounts/new?locale=en'
      check 'account_search_only'
      expect(page).to have_content('Add account to search')
    end
  end
end
