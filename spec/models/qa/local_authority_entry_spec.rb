# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qa::LocalAuthorityEntry, type: :model do
  let(:authority) { Qa::LocalAuthority.create!(name: 'lab_names') }

  it "belongs to a local authority" do
    expect(described_class.reflections['local_authority'].macro).to eq :belongs_to
  end

  describe 'uri' do
    it 'is required on a new term' do
      entry = described_class.new(local_authority: authority, label: 'Anthropology')

      expect(entry).not_to be_valid
      expect(entry.errors[:uri]).to be_present
    end

    it 'rejects a blank one on a new term' do
      expect(described_class.new(local_authority: authority, label: 'Anthropology', uri: '')).not_to be_valid
    end

    # Works store the uri as the term id, so reassigning it orphans every record
    # citing the old value. Deactivating the term is the supported alternative.
    it 'cannot be changed' do
      entry = described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'anth')

      expect(entry.update(uri: 'anthropology')).to eq false
      expect(entry.errors[:uri].join).to include('cannot be changed')
      expect(entry.reload.uri).to eq 'anth'
    end

    it 'cannot be cleared' do
      entry = described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'anth')

      expect(entry.update(uri: nil)).to eq false
      expect(entry.update(uri: '')).to eq false
    end

    it 'leaves the rest of a term editable' do
      entry = described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'anth')

      expect(entry.update(label: 'Anthropology Studies', active: false)).to eq true
    end

    context 'with a term predating the uri rules' do
      let(:legacy) do
        entry = described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'anth')
        entry.update_columns(uri: nil) # rubocop:disable Rails/SkipsModelValidations
        entry.reload
      end

      it 'stays editable without one' do
        expect(legacy.update(active: false)).to eq true
      end

      it 'does not accept a missing uri being filled in' do
        expect(legacy.update(uri: 'anth')).to eq false
        expect(legacy.reload.uri).to be_nil
      end
    end

    it 'is unique within its vocabulary' do
      described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'other')
      duplicate = described_class.new(local_authority: authority, label: 'Assorted', uri: 'other')

      expect(duplicate).not_to be_valid
    end

    # The qa gem indexes uri as globally unique, which stops two vocabularies
    # in one tenant from each having an "other" term.
    it 'may repeat across vocabularies' do
      other_vocabulary = Qa::LocalAuthority.create!(name: 'subjects')
      described_class.create!(local_authority: authority, label: 'Other', uri: 'other')

      expect(described_class.create!(local_authority: other_vocabulary, label: 'Other', uri: 'other')).to be_persisted
    end
  end

  it 'is active by default' do
    entry = described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'anth')

    expect(entry.active).to eq true
  end

  it 'defaults data to an empty hash' do
    entry = described_class.create!(local_authority: authority, label: 'Anthropology', uri: 'anth')

    expect(entry.data).to eq({})
  end

  it 'stores term attributes in the data hash' do
    entry = described_class.create!(
      local_authority: authority,
      label: 'Anthropology',
      uri: 'anth',
      alt_labels: ['Anthro'],
      definition: 'The study of humans.'
    )

    expect(entry.reload.data).to eq('alt_labels' => ['Anthro'], 'definition' => 'The study of humans.')
    expect(entry.alt_labels).to eq ['Anthro']
  end

  describe 'scopes' do
    let!(:live) { described_class.create!(local_authority: authority, label: 'Botany', uri: 'bot') }
    let!(:retired) { described_class.create!(local_authority: authority, label: 'Alchemy', uri: 'alc', active: false) }
    let!(:pinned) { described_class.create!(local_authority: authority, label: 'Zoology', uri: 'zoo', position: 1) }

    it 'separates active from inactive terms' do
      expect(described_class.active).to contain_exactly(live, pinned)
      expect(described_class.inactive).to contain_exactly(retired)
    end

    it 'orders pinned terms first, then unpinned terms by label' do
      expect(described_class.ordered.to_a).to eq [pinned, retired, live]
    end
  end
end
