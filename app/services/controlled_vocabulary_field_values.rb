# frozen_string_literal: true

# A Blacklight `values:` lambda, rather than pointing `add_index_field` at the
# label field directly: Blacklight drops a field whose solr key is absent, so
# repointing would make the row vanish for every work indexed before the label
# fields existed rather than falling back to its id.
class ControlledVocabularyFieldValues
  def self.to_proc
    lambda do |field_config, document, _view_context|
      key = field_config.field.to_s
      document.fetch(label_key(key) || key, nil).presence || document.fetch(key, nil)
    end
  end

  # `license_tesim` -> `license_label_tesim`, matching what the indexer writes.
  # nil when there is no suffix to insert before, so a caller falls back on its
  # own terms rather than comparing the result against what it passed in.
  def self.label_key(key)
    base, _, suffix = key.to_s.rpartition('_')
    return if base.blank? || suffix.blank?

    "#{base}_label_#{suffix}"
  end
end
