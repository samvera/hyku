# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocalVocabularyService do
  describe '.default_label' do
    it 'uses the label the vocabulary carries' do
      expect(described_class.default_label('oer_types', 'label' => 'OER Types')).to eq 'OER Types'
    end

    it 'titleizes the name of a vocabulary that carries none' do
      expect(described_class.default_label('lab_names')).to eq 'Lab Names'
    end
  end

  describe '.default_description' do
    it 'uses the description the vocabulary carries' do
      expect(described_class.default_description({ 'description' => 'Reuse terms.' })).to eq 'Reuse terms.'
    end

    it 'derives one from the terms for a vocabulary that carries none' do
      expect(described_class.default_description({}, term_count: 20, sample_terms: %w[Article Audio Book]))
        .to eq '20 terms, including Article, Audio, and Book.'
    end
  end

  describe '.derived_description' do
    it 'lists the terms outright when there are no more than the sample' do
      expect(described_class.derived_description(2, %w[Student Instructor]))
        .to eq '2 terms: Student and Instructor.'
    end

    it 'counts a vocabulary whose terms have no labels' do
      expect(described_class.derived_description(4, [])).to eq '4 terms.'
    end

    it 'is nil for an empty vocabulary, which has nothing to describe' do
      expect(described_class.derived_description(0, [])).to be_nil
    end
  end

  describe '.seed_vocabulary!' do
    # The qa tables are seeded once in before(:suite) and skipped by truncation,
    # so each example works on a name of its own in a directory of its own.
    let(:path) { Dir.mktmpdir }

    after { FileUtils.remove_entry(path) }

    def write_vocabulary(name, metadata = {})
      contents = metadata.merge('terms' => [{ 'id' => 'a', 'term' => 'A' }])
      File.write(File.join(path, "#{name}.yml"), contents.to_yaml)
      name
    end

    it 'takes the label and description off the vocabulary as it creates it' do
      name = write_vocabulary('described_vocabulary',
                              'label' => 'Practice Research Types',
                              'description' => 'Forms of practice research output.')

      described_class.seed!(path)

      authority = Qa::LocalAuthority.find_by(name:)
      expect(authority.label).to eq 'Practice Research Types'
      expect(authority.description).to eq 'Forms of practice research output.'
    end

    # The case a knapsack lands in: its ymls carry neither key.
    it 'titleizes and describes a vocabulary that carries neither' do
      name = write_vocabulary('bare_vocabulary')

      described_class.seed!(path)

      authority = Qa::LocalAuthority.find_by(name:)
      expect(authority.label).to eq 'Bare Vocabulary'
      expect(authority.description).to eq '1 term: A.'
    end

    it 'fills a blank label on a vocabulary seeded before the columns existed' do
      name = write_vocabulary('legacy_vocabulary', 'label' => 'Legacy Terms')
      Qa::LocalAuthority.create!(name:)

      described_class.seed!(path)

      expect(Qa::LocalAuthority.find_by(name:).label).to eq 'Legacy Terms'
    end

    it 'leaves a label and description an admin edited alone' do
      name = write_vocabulary('edited_vocabulary', 'label' => 'Licenses', 'description' => 'Shipped copy.')
      Qa::LocalAuthority.create!(name:, label: 'Reuse Terms', description: 'What we allow.')

      described_class.seed!(path)

      authority = Qa::LocalAuthority.find_by(name:)
      expect(authority.label).to eq 'Reuse Terms'
      expect(authority.description).to eq 'What we allow.'
    end
  end

  describe '.metadata_by_name' do
    let(:path) { Dir.mktmpdir }

    after { FileUtils.remove_entry(path) }

    it 'reads the copy off disk without the terms' do
      File.write(File.join(path, 'lab_names.yml'),
                 { 'label' => 'Lab Names', 'terms' => [{ 'id' => 'a', 'term' => 'A' }] }.to_yaml)

      expect(described_class.metadata_by_name(path)).to eq('lab_names' => { 'label' => 'Lab Names' })
    end
  end
end
