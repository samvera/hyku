# frozen_string_literal: true

class LocalVocabularyService
  def self.seed!(paths = Qa::Authorities::Local.subauthorities_path)
    files_by_name(paths).map { |name, files| seed_vocabulary!(name, files) }
  end

  # An earlier path wins, matching how HykuKnapsack overrides a Hyku authority.
  def self.files_by_name(paths)
    Array.wrap(paths).flat_map { |path| Dir.glob(File.join(path, '*.yml')).sort }
         .group_by { |file| File.basename(file, '.yml') }
  end

  # A vocabulary is named after its file, and Qa::LocalAuthority rejects a name outside
  # NAME_FORMAT, so one misnamed yml aborts a reseed part way through the tenants.
  def self.invalid_files(paths = Qa::Authorities::Local.subauthorities_path)
    files_by_name(paths).reject { |name, _files| name.match?(Qa::LocalAuthority::NAME_FORMAT) }
                        .values.flatten
  end

  # @param files [Array<String>] every yml this name resolves to, overriding path first
  # @return [Array(String, Integer, Boolean)] name, term count, and whether this run
  #   seeded it — false for a vocabulary the tenant already had
  def self.seed_vocabulary!(name, files)
    contents = files.map { |file| YAML.load_file(file) || {} }
    authority = Qa::LocalAuthority.find_or_initialize_by(name:)
    seeded = authority.persisted? # read before the save below creates it

    backfill_metadata(authority, merged_metadata(contents))
    save_authority!(authority, files.first)

    # Terms on creation only: once a tenant has the vocabulary the rows are theirs, so
    # a term they deleted stays deleted and their wording survives a later run. The
    # dashboard import is how an existing vocabulary gains terms.
    seed_terms!(authority, Array.wrap(contents.first['terms'])) unless seeded

    [name, authority.local_authority_entries.count, !seeded]
  end

  # find_or_create_by! rather than create!: a shipped file can list one id twice
  # (licenses.yml does, for two Creative Commons URIs), and uri is unique per
  # vocabulary.
  def self.seed_terms!(authority, terms)
    terms.each_with_index do |term, index|
      authority.local_authority_entries.find_or_create_by!(uri: term['id']) do |entry|
        entry.label = term['term']
        entry.active = term.fetch('active', true)
        entry.position = index + 1 # from one, as the model numbers a term added later
        entry.data = term.except('id', 'term', 'active')
      end
    end
  end

  # Raised through the instance, not the class: RecordInvalid#initialize takes a record,
  # so `raise e.class, message` hands the message in where the record belongs.
  def self.save_authority!(authority, file)
    authority.save! if authority.changed?
    authority
  rescue ActiveRecord::RecordInvalid => e
    raise e, "#{file}: #{e.message}"
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
