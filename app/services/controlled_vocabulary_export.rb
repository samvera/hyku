# frozen_string_literal: true

require 'csv'

# Streams a vocabulary's terms as CSV (the #701 import template) or as a yaml
# file in the qa authority format.
class ControlledVocabularyExport
  COLUMNS = %w[id label active].freeze

  def initialize(entry)
    @entry = entry
  end

  def filename(format)
    "#{@entry.source_key}.#{format}"
  end

  def csv
    stream(CSV.generate_line(COLUMNS)) do |term|
      CSV.generate_line(term.values_at(*COLUMNS))
    end
  end

  def yml
    stream("#{yml_header}terms:\n") do |term|
      entry = { 'id' => term['id'], 'term' => term['label'], 'active' => term['active'] }
      { 'terms' => [entry] }.to_yaml.delete_prefix("---\nterms:\n")
    end
  end

  private

  # qa's file reader only consumes terms:, so the label and description ride
  # along for the #701 importer without breaking the config-file format.
  def yml_header
    header = { 'source_key' => @entry.source_key, 'label' => @entry.label }
    header['description'] = @entry.description if @entry.description.present?
    header.to_yaml.delete_prefix("---\n")
  end

  # The rows are read up front: a streamed body is drained after Apartment has
  # switched schemas back, so a query run inside it reads the wrong tenant.
  def stream(header)
    rows = terms
    Enumerator.new do |lines|
      lines << header
      rows.each { |term| lines << yield(term) }
    end
  end

  def terms
    return database_terms if @entry.vocabulary

    Qa::Authorities::Local.subauthority_for(@entry.source_key).all.map do |term|
      term = term.with_indifferent_access
      { 'id' => term[:id], 'label' => term[:label], 'active' => term[:active] != false }
    end
  rescue StandardError => e
    Rails.logger.warn("Unable to export terms for #{@entry.source_key}: #{e.message}")
    raise ActiveRecord::RecordNotFound, "No terms to export for #{@entry.source_key}"
  end

  def database_terms
    @entry.vocabulary.local_authority_entries.ordered.pluck(:uri, :label, :active).map do |id, label, active|
      { 'id' => id, 'label' => label, 'active' => active != false }
    end
  end
end
