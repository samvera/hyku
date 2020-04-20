# These methods override 2.5.1 behavior defined in hyrax_helper_behavior.rb
module Hyrax
  module OverrideHelperBehavior
    # @param values [Array{String}] strings to display
    # @param solr_field [String] name of the solr field to link to, without its suffix (:facetable)
    # @param empty_message [String] message to display if no values are passed in
    # @param separator [String] value to join with
    # @return [ActiveSupport::SafeBuffer] the html_safe link
    def link_to_facet_list(values, solr_field, empty_message = "No value entered", separator = ", ")
      return empty_message if values.blank?
      facet_field = Solrizer.solr_name(solr_field, :facetable)
      safe_join(values.map { |item| link_to_facet(item, facet_field) }, separator)
    end

    # Used by the gallery view
    def collection_thumbnail(_document, _image_options = {}, _url_options = {})
      Site.instance.default_collection_image
    end

    def collection_title_by_id(id)
      solr_docs = controller.repository.find(id).docs
      return nil if solr_docs.empty?
      solr_field = solr_docs.first[Solrizer.solr_name("title", :stored_searchable)]
      return nil if solr_field.nil?
      solr_field.first
    end

    # @param [ActionController::Parameters] params first argument for Blacklight::SearchState.new
    # @param [Hash] facet
    # @note Ignores all but the first facet.  Probably a bug.
    def search_state_with_facets(params, facet = {})
      state = Blacklight::SearchState.new(params, CatalogController.blacklight_config)
      return state.params if facet.none?
      state.add_facet_params(Solrizer.solr_name(facet.keys.first, :facetable),
                             facet.values.first)
    end
  end
end
