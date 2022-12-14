# frozen_string_literal: true

require 'cancan/matchers'

# rubocop:disable RSpec/FilePath
RSpec.describe Hyrax::Ability::UserAbility do
  # rubocop:enable RSpec/FilePath
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:hyrax_group) { FactoryBot.create(:group) }

  context 'when user manager' do
    subject { Ability.new(user_manager) }

    let(:user_manager) { FactoryBot.create(:user_manager) }

    it 'allows all user abilities' do
      is_expected.to be_able_to(:create, User)
      is_expected.to be_able_to(:read, user)
      is_expected.to be_able_to(:edit, user)
      is_expected.to be_able_to(:update, user)
      is_expected.to be_able_to(:remove, user)
    end

    it 'allows all group abilities' do
      is_expected.to be_able_to(:create, Hyrax::Group)
      is_expected.to be_able_to(:read, Hyrax::Group)
      is_expected.to be_able_to(:edit, hyrax_group)
      is_expected.to be_able_to(:update, hyrax_group)
      is_expected.to be_able_to(:destroy, hyrax_group)
    end
  end

  context 'when user reader' do
    subject { Ability.new(user_reader) }

    let(:user_reader) { FactoryBot.create(:user_reader) }

    it 'allows user read abilities' do
      is_expected.to be_able_to(:read, user)
    end

    it 'allows group read abilities' do
      is_expected.to be_able_to(:read, Hyrax::Group)
    end

    it 'denies most user abilities' do
      is_expected.not_to be_able_to(:create, User)
      is_expected.not_to be_able_to(:update, user)
      is_expected.not_to be_able_to(:edit, user)
      is_expected.not_to be_able_to(:remove, user)
    end

    it 'denies most group abilities' do
      is_expected.not_to be_able_to(:create, Hyrax::Group)
      is_expected.not_to be_able_to(:update, hyrax_group)
      is_expected.not_to be_able_to(:edit, hyrax_group)
      is_expected.not_to be_able_to(:destroy, hyrax_group)
    end
  end
end
