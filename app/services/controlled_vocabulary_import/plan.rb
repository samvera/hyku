# frozen_string_literal: true

class ControlledVocabularyImport
  # Compares parsed rows against the vocabulary's current terms without writing
  # anything, so the review page can show exactly what confirming will do.
  # Terms match on id (uri); terms absent from the file are never touched.
  class Plan
    Update = Struct.new(:row, :entry, :changes, keyword_init: true)

    # The review page lists at most this many rows per bucket.
    PREVIEW_ROWS = 100

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
      @write_positions && @order_differs
    end

    def changes?
      additions.any? || updates.any? || reorder?
    end

    def valid? = errors.empty?

    # Confirm compares this against a fresh plan, so an import applies only to
    # the state that was reviewed. Every entry's id and timestamp participate,
    # so any change moves the digest.
    def state_digest
      Digest::MD5.hexdigest(@entries.map { |entry| "#{entry.uri}:#{entry.updated_at.to_f}" }.sort.join('|'))
    end

    def additions_preview
      additions.first(PREVIEW_ROWS)
    end

    def additions_overflow
      additions.size - additions_preview.size
    end

    def updates_preview
      updates.first(PREVIEW_ROWS)
    end

    def updates_overflow
      updates.size - updates_preview.size
    end

    def upsert_rows
      now = Time.current
      @next_position = tail_position
      @parsed.rows.each_with_index.filter_map do |row, index|
        entry = entries_by_uri[row.id]
        position = position_for(entry, index)
        next if entry && changes_for(row, entry).empty? && entry.position == position

        # data rides along untouched: the import does not carry those fields,
        # and a full-column upsert would otherwise blank them.
        { local_authority_id: @vocabulary.id, uri: row.id, label: row.label,
          active: desired_active(row, entry), data: entry&.data || {}, position: position,
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
      # Positions are rewritten only from a file that carries every existing
      # term: a partial file's row numbers would collide with the terms it
      # omits and scramble a curated order.
      @write_positions = full_file? && (additions.any? || @order_differs)
      return unless @order_differs && !full_file?
      @warnings << I18n.t('hyku.admin.controlled_vocabulary.import.warnings.partial_order')
    end

    def full_file?
      @full_file ||= (entries_by_uri.keys - @parsed.rows.map(&:id)).empty?
    end

    def changes_for(row, entry)
      changes = {}
      changes['label'] = [entry.label, row.label] if row.label != entry.label
      desired = desired_active(row, entry)
      changes['active'] = [entry.active, desired] if desired != entry.active
      changes
    end

    # Blank means "leave alone" for an existing term and "active" for a new one.
    def desired_active(row, entry)
      return entry ? entry.active : true if row.active.nil?

      row.active
    end

    # nil when any term is unpositioned: a number would jump an appended term
    # ahead of every nil-position term, which sort last.
    def tail_position
      @entries.map(&:position).max if @entries.any? && @entries.all?(&:position)
    end

    # A new term in a partial file appends after the current tail. When the
    # vocabulary is unpositioned, it stays unpositioned too, sorting into the
    # label-ordered group exactly as a form-added term does.
    def position_for(entry, index)
      return index + 1 if @write_positions
      return entry.position if entry

      @next_position += 1 if @next_position
    end

    def entries_by_uri
      @entries_by_uri ||= @entries.index_by(&:uri)
    end

    # A re-uploaded export whose stored positions are nil still sorts the same
    # way, so skipping position writes on a same-order file keeps that round
    # trip a true no-op.
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
