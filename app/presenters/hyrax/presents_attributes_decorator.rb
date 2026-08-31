# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to hand renderers the term labels for a controlled
# property alongside its stored ids.
#
# TODO: TEMPORARY. Remove this file once Hyrax passes label values to renderers
# itself. See app/indexers/hyrax/indexer_decorator.rb for the indexing half.
#
# A renderer holds only `field`, `values`, and `options` — no Solr document — so
# it cannot look up the label itself. The values stay the ids, because a
# URI-valued authority needs the id as its link target, and the labels ride
# alongside in `options` as upstream already does for `subproperties`.
module Hyrax
  module PresentsAttributesDecorator
    def attribute_to_html(field, options = {})
      labels = controlled_labels_for(field)
      options = options.merge(labels:) if labels.present?

      super(field, options)
    end

    private

    # Parallel to the values the renderer receives. nil when the property is not
    # controlled, or the work was indexed before the label fields existed — the
    # renderer then falls back to the ids.
    def controlled_labels_for(field)
      return unless respond_to?(:solr_document)

      document = solr_document
      return unless document.respond_to?(:[])

      label_keys(document, field).lazy
                                 .filter_map { |key| Array(document[key]).presence }
                                 .first
    rescue StandardError => e
      Hyrax.logger.debug("controlled_labels_for(#{field}): #{e.message}")
      nil
    end

    # The suffix follows whatever the property was indexed under, so the pair we
    # know is checked first and any other "<field>_label_*" after it.
    def label_keys(document, field)
      known = ["#{field}_label_tesim", "#{field}_label_sim"]
      prefix = "#{field}_label_"
      others = document.respond_to?(:keys) ? document.keys.grep(/\A#{Regexp.escape(prefix)}/) : []

      (known + others).uniq
    end
  end
end

Hyrax::PresentsAttributes.prepend(Hyrax::PresentsAttributesDecorator)
