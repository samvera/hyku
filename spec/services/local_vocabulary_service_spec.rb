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

    it 'is nil for a vocabulary that carries none, rather than inventing one' do
      expect(described_class.default_description({})).to be_nil
    end
  end

  describe 'the vocabularies hyku ships' do
    it 'describes every one of them' do
      descriptions = described_class.metadata_by_name(Rails.root.join('config', 'authorities'))

      expect(descriptions.values).to all(include('description'))
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
    it 'titleizes a vocabulary that carries neither, and leaves it undescribed' do
      name = write_vocabulary('bare_vocabulary')

      described_class.seed!(path)

      authority = Qa::LocalAuthority.find_by(name:)
      expect(authority.label).to eq 'Bare Vocabulary'
      expect(authority.description).to be_nil
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

    # HykuKnapsack puts its own directory first and overrides a Hyku vocabulary by
    # shipping a file of the same name, which would otherwise take Hyku's copy with it.
    context 'when a knapsack overrides a hyku vocabulary' do
      let(:knapsack) { Dir.mktmpdir }

      after { FileUtils.remove_entry(knapsack) }

      def write(dir, contents)
        File.write(File.join(dir, 'resource_types.yml'),
                   contents.merge('terms' => [{ 'id' => 'a', 'term' => 'A' }]).to_yaml)
      end

      it 'keeps the description hyku ships when the knapsack carries none' do
        write(path, 'label' => 'Resource Types', 'description' => 'The kind of thing a work is.')
        write(knapsack, {})

        expect(described_class.metadata_by_name([knapsack, path]))
          .to eq('resource_types' => { 'label' => 'Resource Types',
                                       'description' => 'The kind of thing a work is.' })
      end

      it 'prefers the copy the knapsack carries' do
        write(path, 'description' => 'The kind of thing a work is.')
        write(knapsack, 'description' => 'Formats this library collects.')

        expect(described_class.metadata_by_name([knapsack, path]))
          .to eq('resource_types' => { 'description' => 'Formats this library collects.' })
      end
    end
  end
end
