# frozen_string_literal: true

class LocalVocabularyService
  def self.seed!(paths = Qa::Authorities::Local.subauthorities_path)
    files_by_name(paths).map do |name, files|
      seed_vocabulary!(name, files.map { |file| YAML.load_file(file) || {} })
    end
  end

  # An earlier path wins, matching how HykuKnapsack overrides a Hyku authority.
  def self.files_by_name(paths)
    Array.wrap(paths).flat_map { |path| Dir.glob(File.join(path, '*.yml')).sort }
         .group_by { |file| File.basename(file, '.yml') }
  end

  # @param contents [Array<Hash>] every yml this name resolves to, overriding path first
  def self.seed_vocabulary!(name, contents)
    terms = Array.wrap(contents.first['terms'])
    authority = Qa::LocalAuthority.find_or_initialize_by(name:)

    backfill_metadata(authority, merged_metadata(contents))
    authority.save! if authority.changed?

    terms.each_with_index do |term, index|
      authority.local_authority_entries.find_or_create_by!(uri: term['id']) do |entry|
        entry.label = term['term']
        entry.active = term.fetch('active', true)
        entry.position = index
        entry.data = term.except('id', 'term', 'active')
      end
    end

    [name, authority.local_authority_entries.count]
  end

  # Only blanks are filled, so a value staff edit in the admin UI survives a reseed.
  def self.backfill_metadata(authority, metadata = {})
    authority.label = default_label(authority.name, metadata) if authority.label.blank?
    authority.description = default_description(metadata) if authority.description.blank?
    authority
  end

  def self.default_label(name, metadata = {})
    metadata['label'].presence || name.to_s.titleize
  end

  # No fallback: the admin index already prints the term count and lists the terms,
  # so a generated description would only repeat the page it sits on.
  def self.default_description(metadata = {})
    metadata['description'].presence
  end

  # Merged, unlike the terms, so a knapsack overriding a Hyku vocabulary keeps
  # Hyku's copy without restating it. Reversed so the earlier path still wins.
  def self.merged_metadata(contents)
    contents.reverse.reduce({}) do |merged, yml|
      merged.merge(yml.except('terms').compact_blank)
    end
  end
end
