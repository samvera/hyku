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
      undescribed = Dir[Rails.root.join('config', 'authorities', '*.yml')]
                    .reject { |file| (YAML.load_file(file) || {})['description'].present? }
                    .map { |file| File.basename(file) }

      expect(undescribed).to be_empty
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

    # Seeding and the model have to agree on where numbering starts, or the first term
    # added in the dashboard skips a number.
    it 'numbers seeded terms from one, as a dashboard-added term is' do
      name = write_vocabulary('sequenced_vocabulary')

      described_class.seed!(path)
      authority = Qa::LocalAuthority.find_by(name:)
      added = authority.local_authority_entries.create!(label: 'B', uri: 'b')

      expect(authority.local_authority_entries.order(:position).pluck(:position)).to eq [1, 2]
      expect(added.position).to eq 2
    end

    # A migration, not a sync: a later run must not undo what staff did to a vocabulary
    # the tenant already has, but still imports one it has not seen.
    context 'run a second time' do
      it 'leaves a term deleted through the dashboard deleted' do
        name = write_vocabulary('settled_vocabulary')
        described_class.seed!(path)
        Qa::LocalAuthority.find_by(name:).local_authority_entries.find_by(uri: 'a').destroy

        described_class.seed!(path)

        expect(Qa::LocalAuthority.find_by(name:).local_authority_entries).to be_empty
      end

      it 'leaves a term edited through the dashboard alone' do
        name = write_vocabulary('renamed_vocabulary')
        described_class.seed!(path)
        Qa::LocalAuthority.find_by(name:).local_authority_entries.find_by(uri: 'a').update!(label: 'Renamed')

        described_class.seed!(path)

        expect(Qa::LocalAuthority.find_by(name:).local_authority_entries.first.label).to eq 'Renamed'
      end

      it 'imports a vocabulary the tenant does not have yet' do
        write_vocabulary('first_vocabulary')
        described_class.seed!(path)
        later = write_vocabulary('second_vocabulary')

        described_class.seed!(path)

        expect(Qa::LocalAuthority.find_by(name: later).local_authority_entries.count).to eq 1
      end

      it 'does not add a term the file gained after seeding' do
        name = write_vocabulary('grown_vocabulary')
        described_class.seed!(path)
        File.write(File.join(path, "#{name}.yml"),
                   { 'terms' => [{ 'id' => 'a', 'term' => 'A' }, { 'id' => 'b', 'term' => 'B' }] }.to_yaml)

        described_class.seed!(path)

        expect(Qa::LocalAuthority.find_by(name:).local_authority_entries.pluck(:uri)).to eq ['a']
      end
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

  # A knapsack names its ymls, and Qa::LocalAuthority will not take every filename.
  describe 'a vocabulary whose filename qa rejects as a name' do
    let(:path) { Dir.mktmpdir }
    let(:file) { File.join(path, 'ETD_Departments.yml') }

    before { File.write(file, { 'terms' => [{ 'id' => 'a', 'term' => 'A' }] }.to_yaml) }

    after { FileUtils.remove_entry(path) }

    it 'names the file rather than the attribute when seeding raises' do
      expect { described_class.seed!(path) }
        .to raise_error(ActiveRecord::RecordInvalid, /ETD_Departments\.yml/)
    end

    it 'lists it ahead of seeding, so a reseed can stop before it writes anything' do
      File.write(File.join(path, 'lab_names.yml'), { 'terms' => [] }.to_yaml)

      expect(described_class.invalid_files(path)).to eq [file]
    end
  end

  # HykuKnapsack puts its own directory first and overrides a Hyku vocabulary by
  # shipping a file of the same name, which would otherwise take Hyku's copy with it.
  describe 'a knapsack overriding a hyku vocabulary' do
    let(:hyku) { Dir.mktmpdir }
    let(:knapsack) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(hyku)
      FileUtils.remove_entry(knapsack)
    end

    def write_vocabulary(dir, name, metadata, term:)
      contents = metadata.merge('terms' => [{ 'id' => term.downcase, 'term' => term }])
      File.write(File.join(dir, "#{name}.yml"), contents.to_yaml)
      name
    end

    it "takes the terms from the knapsack and keeps hyku's copy" do
      name = write_vocabulary(hyku, 'shared_vocabulary',
                              { 'label' => 'Shared Terms', 'description' => "Hyku's copy." }, term: 'Hyku')
      write_vocabulary(knapsack, name, {}, term: 'Knapsack')

      described_class.seed!([knapsack, hyku])

      authority = Qa::LocalAuthority.find_by(name:)
      expect(authority.label).to eq 'Shared Terms'
      expect(authority.description).to eq "Hyku's copy."
      expect(authority.local_authority_entries.pluck(:label)).to eq ['Knapsack']
    end

    it 'prefers the copy the knapsack carries' do
      name = write_vocabulary(hyku, 'overridden_vocabulary', { 'description' => "Hyku's copy." }, term: 'A')
      write_vocabulary(knapsack, name, { 'description' => "The knapsack's copy." }, term: 'A')

      described_class.seed!([knapsack, hyku])

      expect(Qa::LocalAuthority.find_by(name:).description).to eq "The knapsack's copy."
    end
  end
end
