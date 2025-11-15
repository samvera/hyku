# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Enable markdown rendering on work show page metadata

module Hyrax
  module Renderers
    module AttributeRendererDecorator
      include ApplicationHelper

      private

      def attribute_value_to_html(value)
        if field.to_s == 'abstract'
          markdown(value)
        elsif microdata_value_attributes(field).present?
          "<span#{html_attributes(microdata_value_attributes(field))}>#{markdown(li_value(value))}</span>"
        else
          markdown(li_value(value))
        end
      end
    end
  end
end

Hyrax::Renderers::AttributeRenderer.prepend(Hyrax::Renderers::AttributeRendererDecorator)
