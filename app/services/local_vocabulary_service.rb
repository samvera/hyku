# frozen_string_literal: true

class LocalVocabularyService
  def self.seed!(paths = Qa::Authorities::Local.subauthorities_path)
    seed_files(paths).map { |file| seed_vocabulary!(file) }
  end

  # An earlier path wins, matching how HykuKnapsack overrides a Hyku authority.
  def self.seed_files(paths)
    Array.wrap(paths).flat_map { |path| Dir.glob(File.join(path, '*.yml')).sort }
         .uniq { |file| File.basename(file, '.yml') }
  end

  def self.seed_vocabulary!(file)
    name = File.basename(file, '.yml')
    authority = Qa::LocalAuthority.find_or_create_by!(name:)

    Array.wrap((YAML.load_file(file) || {})['terms']).each_with_index do |term, index|
      authority.local_authority_entries.find_or_create_by!(uri: term['id']) do |entry|
        entry.label = term['term']
        entry.active = term.fetch('active', true)
        entry.position = index
        entry.data = term.except('id', 'term', 'active')
      end
    end

    [name, authority.local_authority_entries.count]
  end
end
