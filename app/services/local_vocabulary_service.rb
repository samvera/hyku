# frozen_string_literal: true

class LocalVocabularyService
  def self.seed!(paths = Qa::Authorities::Local.subauthorities_path)
    metadata = metadata_by_name(paths)

    seed_files(paths).map do |file|
      seed_vocabulary!(file, metadata[File.basename(file, '.yml')])
    end
  end

  # An earlier path wins, matching how HykuKnapsack overrides a Hyku authority.
  def self.seed_files(paths)
    files_by_name(paths).values.map(&:first)
  end

  def self.files_by_name(paths)
    Array.wrap(paths).flat_map { |path| Dir.glob(File.join(path, '*.yml')).sort }
         .group_by { |file| File.basename(file, '.yml') }
  end

  def self.seed_vocabulary!(file, metadata = nil)
    name = File.basename(file, '.yml')
    contents = YAML.load_file(file) || {}
    terms = Array.wrap(contents['terms'])
    authority = Qa::LocalAuthority.find_or_initialize_by(name:)

    backfill_metadata(authority, metadata || contents.except('terms'))
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

  # Merged across every file a name resolves to, unlike the terms: a knapsack
  # overriding a Hyku vocabulary keeps Hyku's copy without restating it.
  def self.metadata_by_name(paths = Qa::Authorities::Local.subauthorities_path)
    files_by_name(paths).transform_values { |files| merged_metadata(files) }
  end

  # Reversed so the earlier path, which wins on terms, wins on copy too.
  def self.merged_metadata(files)
    files.reverse.reduce({}) do |merged, file|
      merged.merge((YAML.load_file(file) || {}).except('terms').compact_blank)
    end
  end
end
