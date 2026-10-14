# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to label show page rows in the reader's language: Hyrax picks the profile's
# display_label with the view's template locale (always the default) instead of I18n.locale, and it
# could only humanize labels Hyku keeps under the Solr field names and the form labels
module Hyrax
  module AttributesHelperDecorator
    def conform_options(field_name, view_options)
      labels = view_options.with_indifferent_access[:display_label]
      profile_label = labels.with_indifferent_access[I18n.locale] if labels.is_a?(Hash)
      options = super
      field = (options[:render_term] || field_name).to_s
      options[:label] = hyku_translated_label(profile_label) if profile_label.present?
      options[:label] = hyku_fallback_label(field) if options[:label] == field.humanize
      options
    end

    private

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
