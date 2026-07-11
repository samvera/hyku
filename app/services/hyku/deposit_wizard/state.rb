# frozen_string_literal: true

module Hyku
  module DepositWizard
    # Server-side wizard state, backed by a namespaced session hash. The wizard
    # is a sequence of GET-per-step pages, so choices made on one step are
    # persisted here and read back on the next.
    class State
      PATHS = %w[new add standalone].freeze

      def initialize(store)
        @store = store || {}
      end

      def path
        @store['path']
      end

      def path=(value)
        @store['path'] = value if PATHS.include?(value)
      end

      def work_type
        @store['work_type']
      end

      def work_type=(value)
        @store['work_type'] = value.presence
      end

      def admin_set_id
        @store['admin_set_id']
      end

      def admin_set_id=(value)
        @store['admin_set_id'] = value.presence
      end

      def parent_id
        @store['parent_id']
      end

      def parent_id=(value)
        @store['parent_id'] = value.presence
      end

      # Ids of the Hyrax::UploadedFiles attached on the files step. Stored as
      # strings (the form round-trips them as strings); the commit phase attaches
      # them by id.
      def uploaded_file_ids
        Array(@store['uploaded_file_ids'])
      end

      def uploaded_file_ids=(values)
        @store['uploaded_file_ids'] = Array(values).map(&:to_s).reject(&:blank?).uniq
      end

      # The id of the file that becomes the work's representative/thumbnail.
      # Falls back to the first uploaded file, and never points at a removed one.
      def primary_file_id
        id = @store['primary_file_id']
        return id if uploaded_file_ids.include?(id)

        uploaded_file_ids.first
      end

      def primary_file_id=(value)
        @store['primary_file_id'] = value.presence
      end

      # Submitted work-form values from the details step (plain strings/arrays).
      def attributes
        @store['attributes'] || {}
      end

      def attributes=(value)
        @store['attributes'] = value.to_h
      end

      # Per-file metadata entered on the file_meta step, keyed by uploaded-file
      # id. Each value is a plain-string/array hash of FileSet form fields; a
      # 'visibility' of 'inherit' (or absent) means the file follows the work's
      # visibility rather than setting its own.
      def file_metadata
        @store['file_metadata'] || {}
      end

      def file_metadata=(value)
        @store['file_metadata'] = value.to_h
      end

      # The raw hash, for assignment back into the session.
      def to_h
        @store
      end
    end
  end
end
