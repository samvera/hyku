# frozen_string_literal: true

require 'csv'

class ControlledVocabularyImport
  # Turns an uploaded CSV or yaml file into normalized term rows. Problems
  # collect into errors rather than raising, so the review page can list every
  # bad row at once.
  #
  # Just over the line limit while both file formats are read here. Split the
  # readers out if a third format arrives.
  # rubocop:disable Metrics/ClassLength
  class Parser
    Row = Struct.new(:id, :label, :active, :line, keyword_init: true)
    Result = Struct.new(:rows, :columns, :source_key, :errors, :warnings, keyword_init: true)

    # Only what the terms table and the export surface. Alternate labels and
    # definition join when a phase displays them; until then their columns are
    # ignored with a warning.
    COLUMNS = %w[id label active].freeze
    # One sample value per column, for the upload page's format table.
    EXAMPLES = { 'id' => 'braille', 'label' => 'Braille', 'active' => 'true' }.freeze
    HEADER_ALIASES = { 'identifier' => 'id', 'term' => 'label' }.freeze
    TRUE_VALUES = %w[true 1 yes].freeze
    FALSE_VALUES = %w[false 0 no].freeze

    def self.call(content, filename)
      new(content, filename).call
    end

    def initialize(content, filename)
      @content = content
      # Stray bytes in a filename would make File.extname or String#delete raise.
      @filename = filename.to_s.scrub.delete("\0")
      @rows = []
      @columns = []
      @errors = []
      @warnings = []
    end

    def call
      parse(normalize_encoding)
      check_duplicate_ids
      Result.new(rows: @rows, columns: @columns, source_key: @source_key,
                 errors: @errors, warnings: @warnings)
    end

    private

    def parse(content)
      return if content.nil?

      case File.extname(@filename).downcase
      when '.csv' then parse_csv(content)
      when '.yml', '.yaml' then parse_yaml(content)
      else @errors << error(:unsupported)
      end
    end

    # A null byte is valid UTF-8 but Postgres refuses it, so it gets the same
    # treatment as bad encoding: rejected at parse, not at apply.
    def normalize_encoding
      text = @content.to_s.dup.force_encoding(Encoding::UTF_8)
      return text.delete_prefix("\uFEFF") if text.valid_encoding? && !text.include?("\0")

      @errors << error(:encoding)
      nil
    end

    def parse_csv(content)
      table = CSV.parse(content, headers: true)
      register_columns((table.headers || []).compact.map { |header| normalize_header(header) })
      return @errors << error(:missing_label) unless @columns.include?('label')
      return if size_problem(table.size)

      # Line numbers assume one file line per record, which holds for the
      # template; a quoted embedded newline shifts them slightly.
      table.each_with_index do |record, index|
        build_row(record.to_h.transform_keys { |header| normalize_header(header) }, line: index + 2)
      end
    rescue CSV::MalformedCSVError => e
      @errors << error(:malformed_csv, message: e.message)
    end

    def parse_yaml(content)
      data = YAML.safe_load(content, aliases: false)
      terms = data['terms'] if data.is_a?(Hash)
      return @errors << error(:not_a_vocabulary) unless terms.is_a?(Array)
      return if size_problem(terms.size)

      @source_key = data['source_key']
      register_columns(terms.grep(Hash).flat_map(&:keys).uniq.map { |key| normalize_header(key) })
      terms.each_with_index do |term, index|
        next @errors << error(:invalid_term, line: index + 1) unless term.is_a?(Hash)

        build_row(term.transform_keys { |key| normalize_header(key) }, line: index + 1)
      end
    rescue Psych::Exception => e
      @errors << error(:invalid_yaml, message: e.message)
    end

    def build_row(attrs, line:)
      # Yaml escapes and !!binary can decode to bytes the raw-content check
      # cannot see, which Postgres would refuse at apply.
      return @errors << error(:encoding) if attrs.values.flatten.any? { |value| unsafe_bytes?(value) }

      label = attrs['label'].to_s.strip
      return @errors << error(:blank_label, line: line) if label.blank?

      @rows << Row.new(id: attrs['id'].to_s.strip.presence || label,
                       label: label,
                       active: parse_active(attrs['active'], line),
                       line: line)
    end

    # nil means the cell was blank: new terms default active, existing terms
    # keep their current state.
    def parse_active(value, line)
      return value if value == true || value == false

      normalized = value.to_s.strip.downcase
      return if normalized.empty?
      return true if TRUE_VALUES.include?(normalized)
      return false if FALSE_VALUES.include?(normalized)

      @errors << error(:invalid_active, line: line)
      nil
    end

    def register_columns(keys)
      @columns = keys & COLUMNS
      unknown = keys - COLUMNS
      @warnings << warning(:unknown_columns, columns: unknown.join(', ')) if unknown.any?
    end

    def check_duplicate_ids
      @rows.group_by(&:id).each do |id, dupes|
        next if dupes.size == 1

        @errors << error(:duplicate_id, id: id, lines: dupes.map(&:line).join(', '))
      end
    end

    def unsafe_bytes?(value)
      text = value.to_s.dup.force_encoding(Encoding::UTF_8)
      !text.valid_encoding? || text.include?("\0")
    end

    def normalize_header(header)
      key = header.to_s.strip.downcase
      HEADER_ALIASES.fetch(key, key)
    end

    def size_problem(count)
      @errors << error(:empty) if count.zero?
      @errors << error(:too_many_rows, max: MAX_ROWS) if count > MAX_ROWS
      count.zero? || count > MAX_ROWS
    end

    def error(key, **args)
      I18n.t("hyku.admin.controlled_vocabulary.import.errors.#{key}", **args)
    end

    def warning(key, **args)
      I18n.t("hyku.admin.controlled_vocabulary.import.warnings.#{key}", **args)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
