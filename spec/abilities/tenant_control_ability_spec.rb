# frozen_string_literal: true

require 'cancan/matchers'

# rubocop:disable RSpec/FilePath
RSpec.describe Hyrax::Ability::TenantControlAbility do
  # rubocop:enable RSpec/FilePath
  subject { ability }
  let(:tenant_superadmin) { FactoryBot.create(:tenant_superadmin) }
  let(:tenant_admin) { FactoryBot.create(:admin) }
  let(:basic_user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(current_user) }

  context 'when in standard tenant' do
    before do
      allow(Site).to receive_message_chain(:account, :public_demo_tenant?).and_return(false)
      allow(Site).to receive_message_chain(:account, :search_only?).and_return(false)
      allow(ability).to receive(:current_user).and_return(current_user)
    end

    describe 'when tenant superadmin' do
      let(:current_user) { tenant_superadmin }

      it 'allows all user abilities' do
        is_expected.to be_able_to(:manage, :tenant_controls)
      end
    end

    describe 'when tenant admin' do
      let(:current_user) { tenant_admin }

      it 'allows all user abilities' do
        is_expected.to be_able_to(:manage, :tenant_controls)
      end
    end

    describe 'when basic user' do
      let(:current_user) { basic_user }

      it 'allows all user abilities' do
        is_expected.not_to be_able_to(:manage, :tenant_controls)
      end
    end
  end

  context 'when in demo tenant' do
    before do
      allow(Site).to receive_message_chain(:account, :public_demo_tenant?).and_return(true)
      allow(Site).to receive_message_chain(:account, :search_only?).and_return(false)
    end

    describe 'when tenant superadmin' do
      let(:current_user) { tenant_superadmin }

      it 'allows all user abilities' do
        is_expected.to be_able_to(:manage, :tenant_controls)
      end
    end

    describe 'when tenant admin' do
      let(:current_user) { tenant_admin }

      it 'allows all user abilities' do
        is_expected.not_to be_able_to(:manage, :tenant_controls)
      end
    end

    describe 'when basic user' do
      let(:current_user) { basic_user }

      it 'allows all user abilities' do
        is_expected.not_to be_able_to(:manage, :tenant_controls)
      end
    end
  end
end
