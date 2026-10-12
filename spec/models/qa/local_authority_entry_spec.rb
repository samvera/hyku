# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Qa::LocalAuthorityEntry, type: :model do
  let(:authority) { Qa::LocalAuthority.create!(name: 'lab_names') }

  it "belongs to a local authority" do
    expect(described_class.reflections['local_authority'].macro).to eq :belongs_to
  end

  describe 'uri' do
    it 'is required on a new term' do
      entry = described_class.new(local_authority: authority)

      expect(entry).not_to be_valid
      expect(entry.errors[:uri]).to be_present
    end

    it 'falls back to the label when left blank' do
      entry = described_class.new(local_authority: authority, label: 'Anthropology', uri: '')

      expect(entry).to be_valid
      expect(entry.uri).to eq 'Anthropology'
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

  describe 'defaulting the term id on create' do
    # A vocabulary without real identifiers stores the label itself, which is how the
    # shipped yaml ones read: `Alternative Text` is both the id and the term.
    it 'uses the label verbatim' do
      entry = described_class.create!(local_authority: authority, label: 'Special Collections')

      expect(entry.uri).to eq 'Special Collections'
    end

    it 'keeps a term id the staff member supplied' do
      entry = described_class.create!(local_authority: authority,
                                      label: 'Rare Books',
                                      uri: 'http://id.loc.gov/authorities/sh85110219')

      expect(entry.uri).to eq 'http://id.loc.gov/authorities/sh85110219'
    end

    it 'still refuses a term with no label either' do
      expect(described_class.new(local_authority: authority)).not_to be_valid
    end

    it 'does not change the term id when the label is edited' do
      entry = described_class.create!(local_authority: authority, label: 'Special Collections')
      entry.update!(label: 'Special Collections Reading Room')

      expect(entry.reload.uri).to eq 'Special Collections'
    end
  end

  describe 'position' do
    it 'numbers a new term after the ones already there' do
      first = described_class.create!(local_authority: authority, label: 'Botany', uri: 'bot')
      second = described_class.create!(local_authority: authority, label: 'Alchemy', uri: 'alc')

      expect([first.position, second.position]).to eq [1, 2]
    end

    it 'keeps a position given to it' do
      entry = described_class.create!(local_authority: authority, label: 'Zoology', uri: 'zoo', position: 7)

      expect(entry.position).to eq 7
    end

    # Numbered per vocabulary, so one tenant's terms do not push another's along.
    it 'numbers each vocabulary from the start' do
      other = Qa::LocalAuthority.create!(name: 'other_rooms', label: 'Other Rooms')
      described_class.create!(local_authority: authority, label: 'Botany', uri: 'bot')

      entry = described_class.create!(local_authority: other, label: 'Botany', uri: 'bot')

      expect(entry.position).to eq 1
    end

    # Rows predating the assignment hold NULL, which Postgres sorts last, so the
    # next term has to clear them rather than reuse a low number.
    it 'numbers a new term after rows that have no position' do
      described_class.create!(local_authority: authority, label: 'Alpha', uri: 'a').update_column(:position, nil) # rubocop:disable Rails/SkipsModelValidations
      described_class.create!(local_authority: authority, label: 'Beta', uri: 'b').update_column(:position, nil) # rubocop:disable Rails/SkipsModelValidations

      entry = described_class.create!(local_authority: authority, label: 'Gamma', uri: 'g')

      expect(entry.position).to eq 3
    end
  end

  describe 'scopes' do
    let!(:live) { described_class.create!(local_authority: authority, label: 'Botany', uri: 'bot') }
    let!(:retired) { described_class.create!(local_authority: authority, label: 'Alchemy', uri: 'alc', active: false) }
    let!(:pinned) { described_class.create!(local_authority: authority, label: 'Zoology', uri: 'zoo', position: 1) }

    it 'separates active from inactive terms' do
      expect(authority.local_authority_entries.active).to contain_exactly(live, pinned)
      expect(authority.local_authority_entries.inactive).to contain_exactly(retired)
    end

    # live and retired are numbered on create, so the explicit position: 1 ties with
    # live's and the label breaks it.
    it 'orders by position, then by label' do
      expect(authority.local_authority_entries.ordered.to_a).to eq [live, pinned, retired]
    end
  end
end
