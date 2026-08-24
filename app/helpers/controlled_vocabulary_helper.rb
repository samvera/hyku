# frozen_string_literal: true

module ControlledVocabularyHelper
  INLINE_FIELDS = {
    label: { input: :text_field, options: { class: 'form-control form-control-sm' } },
    description: { input: :text_area, options: { class: 'form-control form-control-sm', rows: 3 } }
  }.freeze

  def controlled_vocabulary_field_input(field)
    INLINE_FIELDS.fetch(field.to_sym)
  end
end
