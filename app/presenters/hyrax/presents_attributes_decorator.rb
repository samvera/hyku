# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to pair each stored value with its indexed label for the linked show fields
# TEMPORARY: delete when samvera/hyrax#7724 is in the bundled Hyrax
module Hyrax
  module PresentsAttributesDecorator
    def value_label_pairs(field)
      values = respond_to?(field) ? Array(send(field)) : []
      labels = controlled_labels_for(field, values) || {}
      values.map { |value| [value, labels[value.to_s].presence] }
    end
  end
end

Hyrax::PresentsAttributes.prepend(Hyrax::PresentsAttributesDecorator)
