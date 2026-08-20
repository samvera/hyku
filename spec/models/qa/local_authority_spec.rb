# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qa::LocalAuthority, type: :model do
  it "can persist data" do
    expect { described_class.create!(name: 'language') }
      .to change(described_class, :count).by(1)
  end

  describe 'validations' do
    it 'requires a name' do
      expect(described_class.new(name: '')).not_to be_valid
    end

    # name_changed? is false on a new record left at nil, so presence can't be
    # guarded on it without letting a nameless vocabulary save.
    it 'rejects a nil name' do
      expect(described_class.new).not_to be_valid
      expect(described_class.new(name: nil).save).to eq false
    end

    it 'rejects a name that is not a usable authority key' do
      authority = described_class.new(name: 'Lab Names')

      expect(authority).not_to be_valid
      expect(authority.errors[:name].join).to include('lowercase letters')
    end

    it 'rejects a duplicate name' do
      described_class.create!(name: 'lab_names')

      expect(described_class.new(name: 'lab_names')).not_to be_valid
    end

    it 'lets a row with a legacy name be relabeled' do
      authority = described_class.create!(name: 'legacy')
      authority.update_columns(name: 'Legacy Name') # rubocop:disable Rails/SkipsModelValidations

      expect(authority.reload.update(label: 'Legacy Name')).to eq true
    end
  end

  describe '#display_label' do
    it 'uses the label when one is set' do
      expect(described_class.new(name: 'lab_names', label: 'Laboratory Names').display_label)
        .to eq 'Laboratory Names'
    end

    it 'falls back to a titleized name' do
      expect(described_class.new(name: 'lab_names').display_label).to eq 'Lab Names'
    end
  end

  describe '#source_key' do
    # Bare, matching how the file-based vocabularies are cited in
    # config/metadata_profiles (e.g. `- licenses`).
    it 'is the value to paste into the metadata profile' do
      expect(described_class.new(name: 'lab_names').source_key).to eq 'lab_names'
    end
  end

  describe '.name_for' do
    it 'turns a label into a usable source key' do
      expect(described_class.name_for('Lab Names')).to eq 'lab_names'
      expect(described_class.name_for('Reading Rooms & Desks')).to eq 'reading_rooms_desks'
      expect(described_class.name_for('Café Terms')).to eq 'cafe_terms'
      expect(described_class.name_for('  spaced  ')).to eq 'spaced'
    end

    it 'produces a key the name validation accepts' do
      ['Lab Names', 'ISO 639-1 Languages', 'Café Terms'].each do |label|
        expect(described_class.name_for(label)).to match(described_class::NAME_FORMAT)
      end
    end
  end

  describe 'deriving the name on create' do
    it 'sets the name from the label' do
      expect(described_class.create!(label: 'Lab Names').name).to eq 'lab_names'
    end

    it 'leaves an explicitly given name alone' do
      expect(described_class.create!(name: 'lab_codes', label: 'Lab Names').name).to eq 'lab_codes'
    end

    # A metadata profile cites the name, and works store terms found through it, so
    # relabeling must not move it.
    it 'does not change the name when the label is edited later' do
      vocabulary = described_class.create!(label: 'Lab Names')
      vocabulary.update!(label: 'Laboratory Names')

      expect(vocabulary.reload.name).to eq 'lab_names'
    end

    it 'still requires something to derive from' do
      expect(described_class.new(label: '')).not_to be_valid
    end
  end
end
