# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

RSpec.describe 'Metadata Profiles Abilities' do
  let(:user) { create(:admin) }
  
  subject { Ability.new(user) }

  context 'for regular (non-search) tenants' do
    before do
      allow(Site.account).to receive(:search_only?).and_return(false)
    end

    it 'allows admin users to manage metadata profiles' do
      is_expected.to be_able_to(:manage, :metadata_profiles)
    end
  end

  context 'for search-only tenants' do
    before do
      # Mock the account to be search-only
      search_account = instance_double("Account")
      allow(search_account).to receive(:search_only?).and_return(true)
      allow(Site).to receive(:account).and_return(search_account)
    end

    it 'does not allow admin users to manage metadata profiles since search-only tenants have no data' do
      is_expected.not_to be_able_to(:manage, :metadata_profiles)
    end
  end

  context 'when no account is present' do
    before do
      allow(Site).to receive(:account).and_return(nil)
    end

    it 'allows admin users to manage metadata profiles (defaults to allowing on nil account)' do
      is_expected.to be_able_to(:manage, :metadata_profiles)
    end
  end
end
