# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Metadata Profiles Abilities' do
  let(:user) { create(:admin) }
  
  subject { Ability.new(user) }

  context 'with flexible metadata enabled' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
    end

    context 'for regular (non-search) tenants' do
      before do
        allow(Site.account).to receive(:search_only?).and_return(false)
      end

      it 'allows admin users to manage metadata profiles' do
        expect(subject).to be_able_to(:manage, :metadata_profiles)
      end
    end

    context 'for search-only tenants' do
      before do
        # Mock the account to be search-only
        search_account = instance_double("Account")
        allow(search_account).to receive(:search_only?).and_return(true)
        allow(Site).to receive(:account).and_return(search_account)
      end

      it 'does not allow users to manage metadata profiles' do
        expect(subject).not_to be_able_to(:manage, :metadata_profiles)
        expect(subject).not_to be_able_to(:create, :metadata_profiles)
        expect(subject).not_to be_able_to(:read, :metadata_profiles)
        expect(subject).not_to be_able_to(:update, :metadata_profiles)
      end
    end
  end

  context 'with flexible metadata disabled' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(false)
    end

    it 'does not set metadata profiles abilities' do
      # When flexible metadata is disabled, the ability check should not interfere
      # We don't check for specific abilities since they're not set
      expect { subject }.not_to raise_error
    end
  end
end
