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
    it 'is the value to paste into the metadata profile' do
      expect(described_class.new(name: 'lab_names').source_key).to eq 'local/lab_names'
    end
  end

  describe '.file_based_names' do
    it 'lists the subauthorities backed by config/authorities YAML' do
      allow(Qa::Authorities::Local).to receive(:names).and_return(%w[licenses])

      expect(described_class.file_based_names).to include('licenses')
    end

    it 'returns an empty list when the authorities directory is missing' do
      allow(Qa::Authorities::Local).to receive(:names).and_raise(Qa::ConfigDirectoryNotFound, 'no directory')

      expect(described_class.file_based_names).to eq []
    end
  end
end
