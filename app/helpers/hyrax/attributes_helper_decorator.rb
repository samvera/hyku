# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to label show page rows in the reader's language: Hyrax picks the profile's
# display_label with the view's template locale (always the default) instead of I18n.locale, it
# could only humanize labels Hyku keeps under the Solr field names and the form labels, and it
# humanizes a plain-text label Hyku has no translation for ("Item ID" became "Item id")
module Hyrax
  module AttributesHelperDecorator
    def conform_options(field_name, view_options)
      labels = view_options.with_indifferent_access[:display_label]
      labels = labels.with_indifferent_access if labels.is_a?(Hash)
      options = super
      field = (options[:render_term] || field_name).to_s
      options[:label] = hyku_profile_label(labels, field, options[:label])
      options
    end

    private

    def hyku_profile_label(labels, field, hyrax_label)
      return hyku_translated_label(labels[I18n.locale]) if labels.is_a?(Hash) && labels[I18n.locale].present?

      written = labels[:default].to_s if labels.is_a?(Hash)
      return hyrax_label if written&.include?('.')
      return hyrax_label unless written.present? || hyrax_label == field.humanize

      known = hyku_fallback_label(field)
      known == field.humanize && written.present? ? written : known
    end

    def hyku_translated_label(label)
      label.include?('.') ? t(label, default: label) : label
    end

    def hyku_fallback_label(field)
      t(:"blacklight.search.fields.show.#{field}_tesim",
        default: [:"blacklight.search.fields.show.#{field}_dtsi",
                  :"blacklight.search.fields.index.#{field}_tesim",
                  :"simple_form.labels.defaults.#{field}",
                  field.humanize])
    end
  end
end

Hyrax::AttributesHelper.prepend Hyrax::AttributesHelperDecorator
