# frozen_string_literal: true

require 'cancan/matchers'

RSpec.describe Hyrax::Ability::ControlledVocabularyAbility do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:current_user) { user }

  describe 'an admin' do
    let(:user) { create(:admin) }

    it { is_expected.to be_able_to(:manage, :controlled_vocabularies) }
    it { is_expected.to be_able_to(:view, :controlled_vocabularies) }

    context 'with flexible metadata' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(true) }

      it { is_expected.to be_able_to(:create, :new_controlled_vocabulary) }
    end

    context 'without flexible metadata' do
      before { allow(Hyrax.config).to receive(:flexible?).and_return(false) }

      it { is_expected.not_to be_able_to(:create, :new_controlled_vocabulary) }

      it 'still manages the vocabularies that exist' do
        expect(ability).to be_able_to(:manage, :controlled_vocabularies)
      end
    end
  end

  # Stubbed on the class rather than the instance: CanCan evaluates ability_logic
  # when the Ability is built, so an instance stub lands too late to affect it.
  describe 'a user who can deposit' do
    let(:user) { create(:user) }

    # Anyone who can deposit through Bulkrax needs to see which terms a field
    # offers, and which of them are retired.
    before { allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(true) }

    it { is_expected.to be_able_to(:view, :controlled_vocabularies) }
    it { is_expected.not_to be_able_to(:manage, :controlled_vocabularies) }
  end

  describe 'a user who cannot deposit' do
    let(:user) { create(:user) }

    before { allow_any_instance_of(Ability).to receive(:can_import_works?).and_return(false) }

    it { is_expected.not_to be_able_to(:view, :controlled_vocabularies) }
    it { is_expected.not_to be_able_to(:manage, :controlled_vocabularies) }
  end
end
