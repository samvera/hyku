# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Enable markdown rendering on work show page metadata
# OVERRIDE Hyrax v5.3.0 Show a controlled term's label, linking to its id when
#   that id is a URI

module Hyrax
  module Renderers
    module AttributeRendererDecorator
      include ApplicationHelper

      private

      def attribute_value_to_html(value)
        return controlled_value_to_html(value) if controlled_label_for(value)
        return markdown(value) if field.to_s == 'abstract'
        # No indexed label: a subclass resolves the value through its own authority,
        # and every work indexed before labels existed arrives that way.
        return super unless instance_of_base_renderer?

        if microdata_value_attributes(field).present?
          "<span#{html_attributes(microdata_value_attributes(field))}>#{markdown(li_value(value))}</span>"
        else
          markdown(li_value(value))
        end
      end

      # True for AttributeRenderer itself, where super is upstream's plain
      # implementation and Hyku's markdown handling has to stay here instead.
      def instance_of_base_renderer?
        self.class == Hyrax::Renderers::AttributeRenderer
      end

      # The generic form of what LicenseAttributeRenderer and
      # RightsStatementAttributeRenderer each do for one hardcoded field.
      def controlled_value_to_html(value)
        with_microdata(controlled_label_or_link(value))
      end

      def controlled_label_or_link(value)
        label = controlled_label_for(value)
        return ERB::Util.h(label) unless Hyrax::AuthorityRenderingHelper.linkable_uri?(value)

        %(<a href="#{ERB::Util.h(value)}" target="_blank" rel="noopener noreferrer">#{ERB::Util.h(label)}</a>)
      end

      # Mirrors the span upstream wraps a value in, which the controlled branch
      # would otherwise skip -- a field such as keyword would lose its itemprop
      # as soon as its vocabulary gained labels.
      def with_microdata(html)
        attributes = microdata_value_attributes(field)
        return html if attributes.blank?

        "<span#{html_attributes(attributes)}>#{html}</span>"
      end

      # Keyed by value rather than paired by position: `render` sorts values when
      # `options[:sort]` is set, so an index would not survive.
      def controlled_label_for(value)
        controlled_labels[value.to_s].presence
      end

      def controlled_labels
        @controlled_labels ||= Array(values).map(&:to_s).zip(Array(options[:labels]).map(&:to_s)).to_h
      end
    end
  end
end

# Each of these defines attribute_value_to_html itself, so prepending to the
# parent alone would leave them rendering ids. Only the two authority-backed
# renderers are listed: a date or rich text is never a controlled term.
[Hyrax::Renderers::AttributeRenderer,
 Hyrax::Renderers::LicenseAttributeRenderer,
 Hyrax::Renderers::RightsStatementAttributeRenderer].each do |renderer|
  renderer.prepend(Hyrax::Renderers::AttributeRendererDecorator)
end
