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

    context 'against the authorities that already exist' do
      it 'rejects a remote service key' do
        authority = described_class.new(name: 'geonames', staff_created: true)

        expect(authority).not_to be_valid
        expect(authority.errors[:name].join).to include('already in use')
      end

      it 'rejects a name registered to an imported copy' do
        expect(described_class.new(name: 'mesh', staff_created: true)).not_to be_valid
      end

      # A profile can cite `getty/aat`, but the format rule rejects a slash before the
      # collision check is reached, so the reserved list holds service keys only.
      it 'rejects a qualified key on its format' do
        authority = described_class.new(name: 'getty/aat', staff_created: true)

        expect(authority).not_to be_valid
        expect(authority.errors[:name].join).to include('lowercase letters')
      end

      # Only the whole key collides. A vocabulary about places does not conflict with
      # geonames merely because the word appears in its name.
      it 'allows a name that only resembles a remote key' do
        expect(described_class.new(name: 'geonames_local', staff_created: true)).to be_valid
      end

      it 'does not reserve a yaml vocabulary name, which is the override path' do
        expect(described_class.new(name: 'map_regions', staff_created: true)).to be_valid
      end

      # The mesh import task creates this row itself, and reserving the name must not
      # stop it.
      it 'leaves a row not created by staff alone' do
        expect(described_class.new(name: 'mesh')).to be_valid
      end

      # One authority that cannot be resolved must not empty the reserved list: a row
      # named `mesh` would then be created and hijack the field wherever a profile
      # cites it.
      it 'still reserves the names it can resolve when one authority fails' do
        allow(Qa::Authorities::Local).to receive(:subauthority_for).and_call_original
        allow(Qa::Authorities::Local).to receive(:subauthority_for)
          .with('resource_types').and_raise(Qa::InvalidSubAuthority, 'boom')

        expect(described_class.new(name: 'mesh', staff_created: true)).not_to be_valid
      end
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

  describe '#resequence_terms' do
    let(:vocabulary) { described_class.create!(name: 'lab_names') }
    let!(:first) { vocabulary.local_authority_entries.create!(label: 'Alpha', uri: 'a') }
    let!(:second) { vocabulary.local_authority_entries.create!(label: 'Beta', uri: 'b') }
    let!(:third) { vocabulary.local_authority_entries.create!(label: 'Gamma', uri: 'g') }

    def labels
      vocabulary.local_authority_entries.ordered.pluck(:label)
    end

    it 'puts the terms in the order given' do
      vocabulary.resequence_terms([third.id, first.id, second.id])

      expect(labels).to eq %w[Gamma Alpha Beta]
    end

    it 'numbers them from one, without gaps' do
      vocabulary.resequence_terms([third.id, first.id, second.id])

      expect(vocabulary.local_authority_entries.ordered.pluck(:position)).to eq [1, 2, 3]
    end

    # A drag moves one term past its neighbor, so writing every row would make a
    # reorder cost the size of the vocabulary rather than the size of the change.
    it 'reports only the terms whose position changed' do
      expect(vocabulary.resequence_terms([second.id, first.id, third.id])).to eq 2
    end

    # The write is driven by this mapping, so its shape is pinned rather than only
    # its size.
    it 'maps each moved term to its new position' do
      moved = vocabulary.send(:moved_terms, [third.id, first.id, second.id],
                              { first.id => 1, second.id => 2, third.id => 3 })

      expect(moved).to eq(third.id => 1, first.id => 2, second.id => 3)
    end

    it 'maps nothing when every term already holds its position' do
      moved = vocabulary.send(:moved_terms, [first.id, second.id],
                              { first.id => 1, second.id => 2 })

      expect(moved).to eq({})
    end

    it 'leaves a term that did not move untouched' do
      expect { vocabulary.resequence_terms([second.id, first.id, third.id]) }
        .not_to change { third.reload.position }
    end

    it 'writes nothing when the order is unchanged' do
      expect(vocabulary.resequence_terms([first.id, second.id, third.id])).to eq 0
    end

    # Ids arrive from form fields, so they are strings.
    it 'accepts ids as strings' do
      vocabulary.resequence_terms([third.id.to_s, first.id.to_s, second.id.to_s])

      expect(labels).to eq %w[Gamma Alpha Beta]
    end

    # Otherwise a posted id would renumber a term this page never showed.
    it 'ignores a term belonging to another vocabulary' do
      other = described_class.create!(name: 'other_rooms')
      stranger = other.local_authority_entries.create!(label: 'Delta', uri: 'd')

      vocabulary.resequence_terms([stranger.id, third.id, first.id, second.id])

      expect(labels).to eq %w[Gamma Alpha Beta]
      expect(stranger.reload.position).to eq 1
    end

    # The display limit caps the page at 500 terms, so a longer vocabulary posts only
    # the ones it showed. Dropping the rest would silently reorder them.
    it 'keeps a term the caller left out, after the ones listed' do
      vocabulary.resequence_terms([third.id, first.id])

      expect(labels).to eq %w[Gamma Alpha Beta]
    end

    # Rows predating positions hold NULL, which never equals a target, so the first
    # reorder is what numbers them.
    it 'numbers terms that have no position yet' do
      vocabulary.local_authority_entries.update_all(position: nil) # rubocop:disable Rails/SkipsModelValidations

      expect(vocabulary.resequence_terms([third.id, first.id, second.id])).to eq 3
      expect(labels).to eq %w[Gamma Alpha Beta]
    end

    it 'ignores an id repeated in the list' do
      vocabulary.resequence_terms([third.id, third.id, first.id, second.id])

      expect(labels).to eq %w[Gamma Alpha Beta]
    end

    it 'leaves the order alone when given nothing' do
      expect(vocabulary.resequence_terms([])).to eq 0
      expect(labels).to eq %w[Alpha Beta Gamma]
    end
  end
end
