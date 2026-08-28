# frozen_string_literal: true

# A Blacklight `values:` lambda that shows a controlled term's label where one is
# indexed, and its stored id otherwise.
#
# Used rather than pointing `add_index_field` at the label field directly, because
# Blacklight drops a field whose solr key is absent — repointing would make the row
# vanish for every work indexed before the label fields existed, rather than
# falling back.
class ControlledVocabularyFieldValues
  def self.to_proc
    lambda do |field_config, document, _view_context|
      key = field_config.field.to_s
      document.fetch(label_key(key), nil).presence || document.fetch(key, nil)
    end
  end

  # `license_tesim` -> `license_label_tesim`, matching what the indexer writes.
  def self.label_key(key)
    base, _, suffix = key.rpartition('_')
    return key if base.blank? || suffix.blank?

    "#{base}_label_#{suffix}"
  end
end
