# frozen_string_literal: true

RSpec.describe ControlledVocabularyTermLoad, clean: true do
  let(:vocabulary) { Qa::LocalAuthority.create!(name: "loader_#{SecureRandom.hex(4)}", label: 'Loader') }
  let(:entry) { ControlledVocabularyCatalog.find!(vocabulary.name) }

  before do
    vocabulary.local_authority_entries.create!(label: 'Alpha', uri: 'alpha')
    vocabulary.local_authority_entries.create!(label: 'Beta', uri: 'beta')
  end

  def taken_during(can_manage:)
    taken = []
    allow_any_instance_of(Qa::LocalAuthority).to receive(:with_lock).and_wrap_original do |original, &block| # rubocop:disable RSpec/AnyInstance
      taken << :lock
      original.call(&block)
    end

    described_class.call(entry: entry, can_manage: can_manage)
    taken
  end

  describe 'for a manager' do
    subject(:load) { described_class.call(entry: entry, can_manage: true) }

    it 'reads the terms' do
      expect(load.terms.map { |term| term['label'] }).to eq %w[Alpha Beta]
    end

    it 'digests them for the reorder to check against' do
      expect(load.state_digest).to eq vocabulary.term_state_digest
    end

    it 'offers a presenter that knows the terms' do
      expect(load.presenter.reorderable?).to be true
    end

    it 'takes the lock the digest needs' do
      expect(taken_during(can_manage: true)).to eq [:lock]
    end
  end

  # A page with no order to save gains nothing from the lock, and a vocabulary can
  # run to tens of thousands of terms the digest would read.
  describe 'for a user who may only view' do
    subject(:load) { described_class.call(entry: entry, can_manage: false) }

    it 'still reads the terms' do
      expect(load.terms.map { |term| term['label'] }).to eq %w[Alpha Beta]
    end

    it 'digests nothing' do
      expect(load.state_digest).to be_nil
    end

    it 'takes no lock' do
      expect(taken_during(can_manage: false)).to be_empty
    end

    it 'offers a presenter with no controls' do
      expect(load.presenter.reorderable?).to be false
    end
  end
end
