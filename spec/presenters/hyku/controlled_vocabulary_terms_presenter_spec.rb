# frozen_string_literal: true

RSpec.describe Hyku::ControlledVocabularyTermsPresenter do
  def entry_for(origin:, vocabulary: nil)
    ControlledVocabularyCatalog::Entry.new(source_key: 'reading_rooms',
                                           label: 'Reading Rooms',
                                           origin: origin,
                                           vocabulary: vocabulary)
  end

  let(:vocabulary) { instance_double(Qa::LocalAuthority) }
  let(:editable) { entry_for(origin: :database, vocabulary: vocabulary) }
  let(:terms) { [{ 'term_id' => 1, 'label' => 'Alpha', 'active' => true }] }

  describe '#controls_possible?' do
    # The controller gates a SELECT ... FOR UPDATE on this, so depending on the terms
    # here would reintroduce the read it exists to avoid.
    it 'answers without the terms' do
      presenter = described_class.new(entry: editable, can_manage: true)

      expect(presenter.controls_possible?).to be true
    end

    it 'refuses a user who may view but not manage' do
      presenter = described_class.new(entry: editable, can_manage: false, terms: terms)

      expect(presenter.controls_possible?).to be false
    end

    it 'refuses a vocabulary whose terms are not this tenant to change' do
      presenter = described_class.new(entry: entry_for(origin: :cached), can_manage: true, terms: terms)

      expect(presenter.controls_possible?).to be false
    end

    it 'refuses a file-backed vocabulary, which has no rows to write' do
      presenter = described_class.new(entry: entry_for(origin: :file), can_manage: true, terms: terms)

      expect(presenter.controls_possible?).to be false
    end
  end

  describe '#togglable?' do
    it 'refuses a vocabulary with no terms yet' do
      presenter = described_class.new(entry: editable, can_manage: true, terms: [])

      expect(presenter.togglable?).to be false
    end

    it 'allows a single term to be retired' do
      presenter = described_class.new(entry: editable, can_manage: true, terms: terms)

      expect(presenter.togglable?).to be true
    end
  end

  describe '#reorderable?' do
    it 'refuses a vocabulary of one term' do
      presenter = described_class.new(entry: editable, can_manage: true, terms: terms)

      expect(presenter.reorderable?).to be false
    end

    it 'allows a vocabulary of more than one' do
      pair = terms + [{ 'term_id' => 2, 'label' => 'Beta', 'active' => true }]
      presenter = described_class.new(entry: editable, can_manage: true, terms: pair)

      expect(presenter.reorderable?).to be true
    end
  end

  describe '#status_of' do
    subject(:presenter) { described_class.new(entry: editable, can_manage: true, terms: terms) }

    it 'reads a boolean flag' do
      expect(presenter.status_of('active' => true)).to eq :active
      expect(presenter.status_of('active' => false)).to eq :inactive
    end

    # The string is truthy to Hyrax::AuthorityService#select_active_options, so the
    # badge has to agree rather than cast it and disagree with the deposit form.
    it 'reads a quoted flag as active, as the deposit form does' do
      expect(presenter.status_of('active' => 'false')).to eq :active
    end

    it 'reports a term that never states one as unknown' do
      expect(presenter.status_of('label' => 'Alpha')).to eq :unknown
    end
  end

  describe 'the status badge' do
    subject(:presenter) { described_class.new(entry: editable, can_manage: true, terms: terms) }

    it 'names each status' do
      expect(presenter.status_label('active' => true)).to eq 'Active'
      expect(presenter.status_label('active' => false)).to eq 'Inactive'
    end

    it 'names an unstated status distinctly' do
      expect(presenter.status_label('label' => 'Alpha'))
        .to eq I18n.t('hyku.admin.controlled_vocabulary.status_unknown')
    end

    it 'draws the eye only to a retired term' do
      expect(presenter.status_variant('active' => false)).to eq 'badge-secondary'
      expect(presenter.status_variant('active' => true)).to eq 'badge-quiet'
      expect(presenter.status_variant('label' => 'Alpha')).to eq 'badge-quiet'
    end
  end

  describe 'the reorder controls' do
    subject(:presenter) { described_class.new(entry: editable, can_manage: true, terms: terms) }

    it 'names the term in the handle label' do
      expect(presenter.reorder_handle_label('label' => 'Alpha')).to include 'Alpha'
    end

    it 'distinguishes the two directions' do
      earlier = presenter.move_label({ 'label' => 'Alpha' }, -1)
      later = presenter.move_label({ 'label' => 'Alpha' }, 1)

      expect(earlier).to include 'Alpha'
      expect(later).to include 'Alpha'
      expect(earlier).not_to eq later
    end
  end

  describe 'the toggle' do
    subject(:presenter) { described_class.new(entry: editable, can_manage: true, terms: terms) }

    it 'offers to retire an active term' do
      expect(presenter.toggle_value('active' => true)).to eq 'false'
      expect(presenter.toggle_variant('active' => true)).to eq 'btn-outline-secondary'
    end

    it 'offers to restore a retired one' do
      expect(presenter.toggle_value('active' => false)).to eq 'true'
      expect(presenter.toggle_variant('active' => false)).to eq 'btn-outline-primary'
    end

    it 'offers to retire a term whose status is unstated' do
      expect(presenter.toggle_value('label' => 'Alpha')).to eq 'false'
    end
  end
end
