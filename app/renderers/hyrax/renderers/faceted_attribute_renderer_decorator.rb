# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to link a controlled term through the label facet whenever it has an
#   indexed label, including a label that is its id, and only when the caller confirms the
#   label facet is registered
# TEMPORARY: delete when samvera/hyrax#7724 is in the bundled Hyrax
module Hyrax
  module Renderers
    module FacetedAttributeRendererDecorator
      private

      def label_facet?(value)
        labels = options[:labels]
        labels.is_a?(Hash) && labels[value.to_s].present? && options.fetch(:label_facet_registered, false)
      end
    end
  end
end

Hyrax::Renderers::FacetedAttributeRenderer.prepend(Hyrax::Renderers::FacetedAttributeRendererDecorator)
