# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to choose a collection page's fields in one place, for every theme:
#   - an app's own list (Hyrax.config.collection_terms), in its order, when it sets one
#   - otherwise the profile's properties, in profile order, when the page asks for them (dynamic: true)
#   - otherwise the presenter's terms, as Hyrax shows them, less a flexible collection's fields the profile
#     keeps off collection pages or restricts by an admin_only or editor_only indexing flag the viewer fails
#   - from a list or the profile, a flexible collection shows only properties the profile shows, leaving out
#     card compounds and those marked view: { collection_page: false } or { show_page: false }
#   - a flexible collection's view settings come from its profile entries (Hyku::CollectionProfileReaders),
#     so a property limited to a context never applies to a collection or admin set page
#   - only an app's listed properties take their labels and rendering from the profile; a listed property
#     whose render term the presenter cannot read keeps the profile's label and renders as Hyrax does
# TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax
module Hyrax
  module CollectionsHelperDecorator
    def collection_terms_for(presenter, dynamic: false)
      listed = presenter.try(:listed_terms)
      return presenter.terms unless flexible_collection?(presenter)

      options = collection_view_options(presenter)
      return presenter.terms.reject { |term| hidden_by_default?(presenter, term, options[term]) } unless listed || dynamic

      (listed || options.keys).select { |term| collection_term_shown?(presenter, term, options[term]) }
    end

    def collection_terms_with_values(presenter, dynamic: false)
      return default_terms_with_values(presenter) unless presenter.try(:listed_terms) || dynamic

      collection_terms_for(presenter, dynamic:).select { |term| presenter.readable_term?(term) && presenter[term].present? }
    end

    def collection_metadata_label(collection, field)
      options = listed_profile_options(collection, field)
      options ? options[:label] : super
    end

    def collection_metadata_value(collection, field)
      options = listed_profile_options(collection, field)
      return super unless options && collection.respond_to?(conform_field(field, options))

      row = collection.attribute_to_html(conform_field(field, options), options.merge(html_dl: true))
      Nokogiri::HTML::DocumentFragment.parse(row.to_s).at_css('dd')&.inner_html&.html_safe # rubocop:disable Rails/OutputSafety
    end

    private

    def flexible_collection?(presenter)
      presenter.solr_document.try(:flexible?)
    end

    def collection_view_options(presenter)
      @collection_view_options ||= {}
      @collection_view_options[presenter.id] ||= profile_view_definitions(presenter)
    end

    def profile_view_definitions(presenter)
      presenter.profile_properties.each_with_object({}) do |(name, details), definitions|
        options = Hyrax::M3SchemaLoader::M3AttributeDefinition.new(name, details).view_options
        definitions[name.to_sym] = options unless options.without(:display_label, :admin_only, :editor_only).empty?
      end
    end

    def collection_term_shown?(presenter, term, options)
      return false unless options

      view_options = options.with_indifferent_access
      return false if view_options[:collection_page] == false || view_options[:show_page] == false

      !compound_card_field?(presenter, term) && !restricted_from_viewer?(presenter, term, view_options)
    end

    def default_terms_with_values(presenter)
      return presenter.terms_with_values unless flexible_collection?(presenter)

      options = collection_view_options(presenter)
      presenter.terms_with_values.reject { |term| hidden_by_default?(presenter, term, options[term]) }
    end

    def hidden_by_default?(presenter, term, options)
      options&.with_indifferent_access&.dig(:collection_page) == false || restricted_from_viewer?(presenter, term, options)
    end

    def restricted_from_viewer?(presenter, term, options)
      flags = Array(presenter.try(:profile_property, term)&.dig('indexing'))
      flags += %w[admin_only editor_only].select { |flag| options&.with_indifferent_access&.dig(flag) }
      (flags.include?('admin_only') && !current_user&.admin?) || (flags.include?('editor_only') && !presenter.try(:editor?))
    end

    def listed_profile_options(collection, field)
      return unless collection.try(:listed_terms) && flexible_collection?(collection)
      return if collection.compound_term?(field)

      options = collection_view_options(collection)[field.to_sym]
      return unless options

      conform_options(field, options.deep_dup.with_indifferent_access)
    end
  end
end

Hyrax::CollectionsHelper.prepend(Hyrax::CollectionsHelperDecorator)
