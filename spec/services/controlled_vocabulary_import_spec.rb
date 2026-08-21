# frozen_string_literal: true

RSpec.describe ControlledVocabularyImport do
  let(:vocabulary) { Qa::LocalAuthority.create!(name: 'reading_rooms', label: 'Reading Rooms') }

  def plan_for(content, filename: 'terms.csv')
    described_class.new(content: content, filename: filename, vocabulary: vocabulary).plan
  end

  def apply(content, filename: 'terms.csv')
    described_class.new(content: content, filename: filename, vocabulary: vocabulary).apply!
  end

  def terms
    vocabulary.local_authority_entries.reload.to_a
  end

  describe 'csv parsing' do
    it 'reads the export columns and defaults the id from the label' do
      plan = plan_for("id,label,active\n,Braille,true\n")

      expect(plan.errors).to be_empty
      expect(plan.additions.map(&:id)).to eq ['Braille']
    end

    it 'accepts identifier and term as column aliases' do
      plan = plan_for("Identifier,Term\nbraille,Braille\n")

      expect(plan.errors).to be_empty
      expect(plan.additions.first.to_h).to include(id: 'braille', label: 'Braille')
    end

    it 'reads a file with a byte order mark and windows line endings' do
      plan = plan_for("\uFEFFid,label\r\nbraille,Braille\r\n")

      expect(plan.errors).to be_empty
      expect(plan.additions.size).to eq 1
    end

    it 'coerces active spellings and rejects anything else' do
      plan = plan_for("label,active\nA,TRUE\nB,0\nC,\nD,maybe\n")

      expect(plan.additions.map(&:active)).to eq [true, false, nil, nil]
      expect(plan.errors).to contain_exactly a_string_including('Row 5')
    end

    it 'warns about unknown columns without blocking the import' do
      plan = plan_for("label,alt_label\nBraille,Moon type\n")

      expect(plan.errors).to be_empty
      expect(plan.warnings).to contain_exactly a_string_including('alt_label')
    end

    it 'requires a label column' do
      expect(plan_for("id,active\nbraille,true\n").errors).to contain_exactly a_string_including('label column')
    end

    it 'reports the line of a blank label' do
      plan = plan_for("id,label\nbraille,Braille\nmoon,\n")

      expect(plan.errors).to contain_exactly a_string_including('Row 3')
    end

    it 'refuses a file where two headers mean the same column' do
      plan = plan_for("label,term\nRealLabel,OtherLabel\n")

      expect(plan.errors).to contain_exactly a_string_including('label')
      expect(plan.additions).to be_empty
    end

    it 'caps the id and label length, because the id is permanent' do
      plan = plan_for("label\n#{'x' * 256}\n")

      expect(plan.errors).to contain_exactly a_string_including('255')
    end

    it 'reports duplicate ids, whether typed or defaulted from the label' do
      plan = plan_for("id,label\nbraille,Braille\nbraille,Braille Type\n,braille\n")

      expect(plan.errors).to contain_exactly a_string_including('Rows 2, 3, 4')
    end

    it 'reports a file the CSV reader cannot parse' do
      expect(plan_for(%(label\n"unclosed\n)).errors).to contain_exactly a_string_including('CSV')
    end

    it 'reports a file with no term rows' do
      expect(plan_for("id,label\n").errors).to contain_exactly a_string_including('no term rows')
    end

    it 'declines a file over the row cap, naming the cap' do
      stub_const('ControlledVocabularyImport::MAX_ROWS', 2)

      plan = plan_for("label\nA\nB\nC\n")

      expect(plan.errors).to contain_exactly a_string_including('2')
      expect(plan.additions).to be_empty
    end

    it 'rejects non utf-8 content' do
      expect(plan_for("label\n\xff\xfe".dup.force_encoding(Encoding::BINARY)).errors)
        .to contain_exactly a_string_including('UTF-8')
    end

    it 'rejects an unsupported file type' do
      expect(plan_for('label', filename: 'terms.xlsx').errors).to contain_exactly a_string_including('.csv')
    end

    it 'survives a null byte smuggled into the filename' do
      expect(plan_for("label\nBraille\n", filename: "terms\0.csv").errors).to be_empty
    end

    it 'survives a filename with broken encoding' do
      expect(plan_for("label\nBraille\n", filename: "ter\xFFms.csv".dup.force_encoding(Encoding::UTF_8)).errors)
        .to be_empty
    end

    it 'rejects content with a null byte, which the database would refuse' do
      expect(plan_for("label\nBra\0ille\n").errors).to contain_exactly a_string_including('UTF-8')
    end
  end

  describe 'yaml parsing' do
    it 'reads the qa authority format' do
      plan = plan_for(<<~YAML, filename: 'terms.yml')
        source_key: reading_rooms
        terms:
        - id: braille
          term: Braille
          active: false
        - term: Moon Type
      YAML

      expect(plan.errors).to be_empty
      expect(plan.warnings).to be_empty
      expect(plan.additions.map(&:to_h)).to include(
        hash_including(id: 'braille', label: 'Braille', active: false),
        hash_including(id: 'Moon Type', label: 'Moon Type', active: nil)
      )
    end

    it 'warns about per-term keys the import does not carry yet' do
      plan = plan_for(<<~YAML, filename: 'terms.yml')
        terms:
        - term: Braille
          alt_labels:
          - Moon type
          definition: Raised-dot writing.
      YAML

      expect(plan.errors).to be_empty
      expect(plan.warnings).to contain_exactly a_string_including('alt_labels, definition')
      expect(plan.additions.map(&:label)).to eq ['Braille']
    end

    it 'warns when the file was exported from a different vocabulary' do
      plan = plan_for("source_key: licenses\nterms:\n- term: Braille\n", filename: 'terms.yml')

      expect(plan.warnings).to contain_exactly a_string_including('licenses')
    end

    it 'reports a yaml file with no terms list' do
      expect(plan_for("label: Reading Rooms\n", filename: 'terms.yml').errors)
        .to contain_exactly a_string_including('terms')
    end

    it 'reports unparseable yaml' do
      expect(plan_for("terms:\n\t- bad", filename: 'terms.yml').errors)
        .to contain_exactly a_string_including('yaml')
    end

    it 'rejects a null byte a yaml escape decodes to' do
      expect(plan_for(%(terms:\n- term: "Bra\\0ille"\n), filename: 'terms.yml').errors)
        .to contain_exactly a_string_including('UTF-8')
    end

    it 'rejects invalid bytes a yaml binary tag decodes to' do
      expect(plan_for(%(terms:\n- term: !!binary "QnJh/2lsbGU="\n), filename: 'terms.yml').errors)
        .to contain_exactly a_string_including('UTF-8')
    end

    it 'reports a terms list entry that is not a term' do
      plan = plan_for("terms:\n- just a string\n- term: Braille\n", filename: 'terms.yml')

      expect(plan.errors).to contain_exactly a_string_including('Row 1')
      expect(plan.additions.size).to eq 1
    end

    it 'rejects a nested value instead of stringifying it into a term' do
      plan = plan_for("terms:\n- term:\n    a: 1\n", filename: 'terms.yml')

      expect(plan.errors).to contain_exactly a_string_including('Row 1')
      expect(plan.additions).to be_empty
    end

    it 'rejects a sequence value instead of stringifying it into a term' do
      plan = plan_for("terms:\n- term:\n  - alpha\n  - beta\n", filename: 'terms.yml')

      expect(plan.errors).to contain_exactly a_string_including('Row 1')
      expect(plan.additions).to be_empty
    end

    it 'warns about the wrong source key even when the file is empty' do
      plan = plan_for("source_key: licenses\nterms: []\n", filename: 'terms.yml')

      expect(plan.warnings).to contain_exactly a_string_including('licenses')
    end
  end

  describe 'the plan' do
    before do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille',
                                                 definition: 'Raised-dot writing.')
      vocabulary.local_authority_entries.create!(label: 'Captions', uri: 'captions')
    end

    it 'classifies additions, updates, and unchanged rows' do
      plan = plan_for("id,label\nbraille,Braille\ncaptions,Closed Captions\nhaptic,Haptic\n")

      expect(plan.additions.map(&:id)).to eq ['haptic']
      expect(plan.updates.map { |u| u.row.id }).to eq ['captions']
      expect(plan.updates.first.changes).to eq('label' => ['Captions', 'Closed Captions'])
      expect(plan.unchanged_count).to eq 1
    end

    it 'matches a defaulted id against an existing term id' do
      vocabulary.local_authority_entries.create!(label: 'Sign Language', uri: 'Sign Language')

      plan = plan_for("label,active\nSign Language,false\n")

      expect(plan.additions).to be_empty
      expect(plan.updates.first.changes).to eq('active' => [true, false])
      expect(plan.deactivations).to eq 1
    end

    it 'leaves attributes alone when their column is absent' do
      expect(plan_for("id,label\nbraille,Braille\n").changes?).to be false
    end

    it 'keeps a term current when blank active means leave alone' do
      vocabulary.local_authority_entries.find_by(uri: 'captions').update!(active: false)

      expect(plan_for("id,label,active\ncaptions,Captions,\n").changes?).to be false
    end

    it 'detects a reorder when the file carries every term' do
      plan = plan_for("id,label\ncaptions,Captions\nbraille,Braille\n")

      expect(plan.reorder?).to be true
      expect(plan.changes?).to be true
    end

    it 'never applies row order from a file that leaves terms out' do
      vocabulary.local_authority_entries.create!(label: 'Haptic', uri: 'haptic')

      plan = plan_for("id,label\ncaptions,Captions\nbraille,Braille\n")

      expect(plan.reorder?).to be false
      expect(plan.changes?).to be false
      expect(plan.upsert_rows).to be_empty
      expect(plan.warnings).to contain_exactly a_string_including('row order was not applied')
    end

    it 'never touches terms missing from the file' do
      plan = plan_for("id,label\nbraille,Braille\n")

      expect(plan.changes?).to be false
      expect(plan.upsert_rows).to be_empty
    end

    it 'caps the review preview and reports the overflow' do
      stub_const('ControlledVocabularyImport::Plan::PREVIEW_ROWS', 2)

      plan = plan_for("label\nA\nB\nC\n")

      expect(plan.additions_preview.map(&:label)).to eq %w[A B]
      expect(plan.additions_overflow).to eq 1
    end

    it 'changes its digest when the vocabulary changes' do
      before_digest = plan_for("id,label\nbraille,Braille\n").state_digest
      vocabulary.local_authority_entries.find_by(uri: 'captions').update!(label: 'CC')
      vocabulary.reload

      expect(plan_for("id,label\nbraille,Braille\n").state_digest).not_to eq before_digest
    end
  end

  describe 'round trips with the export' do
    let(:entry) do
      ControlledVocabularyCatalog::Entry.new(source_key: 'reading_rooms', origin: :database,
                                             vocabulary: vocabulary, label: 'Reading Rooms')
    end

    before do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille')
      vocabulary.local_authority_entries.create!(label: 'Captions', uri: 'captions', active: false)
    end

    it 'reports an unchanged csv download as no changes and writes nothing' do
      csv = ControlledVocabularyExport.new(entry).csv.to_a.join
      stamps = terms.map(&:updated_at)

      plan = plan_for(csv)
      expect(plan.changes?).to be false
      expect(plan.valid?).to be true

      apply(csv)
      expect(terms.map(&:updated_at)).to eq stamps
    end

    it 'reports an unchanged yaml download as no changes' do
      yml = ControlledVocabularyExport.new(entry).yml.to_a.join

      expect(plan_for(yml, filename: 'reading_rooms.yml').changes?).to be false
    end
  end

  describe 'apply!' do
    it 'creates terms with the file order and defaults' do
      apply("id,label,active\n,Braille,\nhap,Haptic,false\n")

      braille, haptic = terms.sort_by(&:position)
      expect(braille).to have_attributes(uri: 'Braille', label: 'Braille', active: true, position: 1)
      expect(haptic).to have_attributes(uri: 'hap', active: false, position: 2)
    end

    it 'updates matched terms in place, keeping their id and created_at' do
      existing = vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille', created_at: 2.days.ago)

      apply("id,label,active\nbraille,Braille Type,false\n")

      expect(terms.size).to eq 1
      expect(terms.first).to have_attributes(uri: 'braille', label: 'Braille Type', active: false,
                                             created_at: be_within(1.second).of(existing.created_at))
    end

    it 'keeps stored data the import does not carry' do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille',
                                                 definition: 'Raised-dot writing.')

      apply("id,label,active\nbraille,Braille Type,true\n")

      expect(terms.first.label).to eq 'Braille Type'
      expect(terms.first.definition).to eq 'Raised-dot writing.'
    end

    it 'renumbers positions when the file reorders terms' do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille', position: 1)
      vocabulary.local_authority_entries.create!(label: 'Captions', uri: 'captions', position: 2)

      apply("id,label\ncaptions,Captions\nbraille,Braille\n")

      expect(terms.sort_by(&:position).map(&:uri)).to eq %w[captions braille]
    end

    it 'appends new terms after the tail when the file leaves terms out' do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille', position: 1)
      vocabulary.local_authority_entries.create!(label: 'Captions', uri: 'captions', position: 2)

      apply("id,label\nhaptic,Haptic\n")

      expect(terms.find { |term| term.uri == 'braille' }.position).to eq 1
      expect(terms.find { |term| term.uri == 'captions' }.position).to eq 2
      expect(terms.find { |term| term.uri == 'haptic' }.position).to eq 3
    end

    it 'appends past legacy unpositioned terms, matching the term form' do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille')
      vocabulary.local_authority_entries.create!(label: 'Transcript', uri: 'transcript')
      # Rows predating the position default hold NULL.
      vocabulary.local_authority_entries.update_all(position: nil) # rubocop:disable Rails/SkipsModelValidations

      apply("id,label\nhaptic,Haptic\n")

      expect(terms.find { |term| term.uri == 'haptic' }.position).to eq 3
    end

    it 'refuses to apply a plan with errors' do
      vocabulary.local_authority_entries.create!(label: 'Braille', uri: 'braille')

      expect { apply("id,label\nbraille,New Braille\nmoon,\n") }.to raise_error(ArgumentError)
      expect(terms.first.label).to eq 'Braille'
    end

    it 'commits nothing when a batch fails partway' do
      stub_const('ControlledVocabularyImport::BATCH_SIZE', 1)
      calls = 0
      allow(Qa::LocalAuthorityEntry).to receive(:upsert_all).and_wrap_original do |original, *args, **kwargs|
        calls += 1
        raise ActiveRecord::StatementInvalid, 'boom' if calls == 2

        original.call(*args, **kwargs)
      end

      expect { apply("label\nA\nB\nC\n") }.to raise_error(ActiveRecord::StatementInvalid)
      expect(terms).to be_empty
    end

    it 'imports in batches' do
      stub_const('ControlledVocabularyImport::BATCH_SIZE', 2)

      apply("label\n#{(1..5).map { |n| "Term #{n}\n" }.join}")

      expect(terms.size).to eq 5
    end
  end
end
