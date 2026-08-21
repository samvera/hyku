# frozen_string_literal: true

class ControlledVocabularyImport
  # Compares parsed rows against the vocabulary's current terms without writing
  # anything, so the review page can show exactly what confirming will do.
  # Terms match on id (uri); terms absent from the file are never touched.
  class Plan
    Update = Struct.new(:row, :entry, :changes, keyword_init: true)

    attr_reader :errors, :warnings, :additions, :updates, :unchanged_count

    def initialize(parsed, vocabulary)
      @parsed = parsed
      @vocabulary = vocabulary
      @errors = parsed.errors
      @warnings = parsed.warnings + source_key_warnings
      @entries = vocabulary.local_authority_entries.to_a
      classify
    end

    def deactivations
      updates.count { |update| update.changes['active']&.last == false }
    end

    def reorder?
      @order_differs
    end

    def changes?
      additions.any? || updates.any? || reorder?
    end

    def valid?
      errors.empty?
    end

    # Confirm compares this against a fresh plan, so an import applies only to
    # the state that was reviewed.
    def state_digest
      "#{@entries.size}-#{@entries.map(&:updated_at).max.to_f}"
    end

    def upsert_rows
      now = Time.current
      @parsed.rows.each_with_index.filter_map do |row, index|
        entry = entries_by_uri[row.id]
        position = write_positions? ? index + 1 : entry&.position
        next if entry && changes_for(row, entry).empty? && entry.position == position

        { local_authority_id: @vocabulary.id, uri: row.id, label: row.label,
          active: desired_active(row, entry), data: data_for(row, entry), position: position,
          created_at: entry&.created_at || now, updated_at: now }
      end
    end

    private

    def classify
      @additions = []
      @updates = []
      @unchanged_count = 0
      @parsed.rows.each do |row|
        entry = entries_by_uri[row.id]
        next @additions << row if entry.nil?

        changes = changes_for(row, entry)
        changes.empty? ? @unchanged_count += 1 : @updates << Update.new(row: row, entry: entry, changes: changes)
      end
      @order_differs = order_differs?
    end

    def changes_for(row, entry)
      changes = {}
      changes['label'] = [entry.label, row.label] if row.label != entry.label
      desired = desired_active(row, entry)
      changes['active'] = [entry.active, desired] if desired != entry.active
      changes['alt_labels'] = [Array(entry.alt_labels), row.alt_labels] if alt_labels_change?(row, entry)
      changes['definition'] = [entry.definition, row.definition] if definition_change?(row, entry)
      changes
    end

    # Blank means "leave alone" for an existing term and "active" for a new one.
    def desired_active(row, entry)
      return entry ? entry.active : true if row.active.nil?

      row.active
    end

    # A column absent from the file leaves the attribute untouched; a present
    # column is the truth, so a blank cell clears the stored value.
    def alt_labels_change?(row, entry)
      column?('alt_labels') && Array(entry.alt_labels) != row.alt_labels
    end

    def definition_change?(row, entry)
      column?('definition') && entry.definition.presence != row.definition
    end

    def data_for(row, entry)
      data = entry ? entry.data.dup : {}
      data['alt_labels'] = row.alt_labels if column?('alt_labels')
      data['definition'] = row.definition if column?('definition')
      data.compact
    end

    def column?(name)
      @parsed.columns.include?(name)
    end

    def entries_by_uri
      @entries_by_uri ||= @entries.index_by(&:uri)
    end

    # Positions are only written when the file actually changes the order (or
    # adds terms, which need slots). A re-uploaded export whose stored
    # positions are nil still sorts the same way, so skipping keeps that
    # round trip a true no-op.
    def write_positions?
      additions.any? || @order_differs
    end

    def order_differs?
      file_uris = @parsed.rows.map(&:id).select { |uri| entries_by_uri.key?(uri) }
      wanted = file_uris.to_set
      current = @vocabulary.local_authority_entries.ordered.pluck(:uri)
      current.select { |uri| wanted.include?(uri) } != file_uris
    end

    def source_key_warnings
      return [] if @parsed.source_key.blank? || @parsed.source_key == @vocabulary.name

      [I18n.t('hyku.admin.controlled_vocabulary.import.warnings.source_key_mismatch',
              source_key: @parsed.source_key, name: @vocabulary.name)]
    end
  end
end
