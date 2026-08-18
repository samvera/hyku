# frozen_string_literal: true

class LocalVocabularyService
  SAMPLE_TERM_COUNT = 3

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
    contents = YAML.load_file(file) || {}
    terms = Array.wrap(contents['terms'])
    authority = Qa::LocalAuthority.find_or_initialize_by(name:)

    backfill_metadata(authority,
                      contents,
                      term_count: terms.size,
                      sample_terms: terms.first(SAMPLE_TERM_COUNT).map { |term| term['term'] })
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
  def self.backfill_metadata(authority, metadata = {}, term_count: 0, sample_terms: [])
    authority.label = default_label(authority.name, metadata) if authority.label.blank?
    authority.description = default_description(metadata, term_count:, sample_terms:) if authority.description.blank?
    authority
  end

  def self.default_label(name, metadata = {})
    metadata['label'].presence || name.to_s.titleize
  end

  def self.default_description(metadata = {}, term_count: 0, sample_terms: [])
    metadata['description'].presence || derived_description(term_count, sample_terms)
  end

  # Stored rather than computed, so it goes stale as terms change. It is a
  # starting point for staff to replace, not a description that stays true.
  def self.derived_description(term_count, sample_terms)
    samples = Array.wrap(sample_terms).compact_blank
    return nil if term_count.zero?

    count = "#{term_count} #{'term'.pluralize(term_count)}"
    return "#{count}." if samples.empty?
    return "#{count}: #{samples.to_sentence}." if term_count <= samples.size

    "#{count}, including #{samples.to_sentence}."
  end

  def self.metadata_by_name(paths = Qa::Authorities::Local.subauthorities_path)
    seed_files(paths).index_by { |file| File.basename(file, '.yml') }
                     .transform_values { |file| (YAML.load_file(file) || {}).except('terms') }
  end
end
