# frozen_string_literal: true

# this class must inherit from the IiifPrint builder so it can be set to the config.search_builder_class and
# include all necessary methods
class AdvSearchBuilder < IiifPrint::CatalogSearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder

  # The default_processor_chain is an array of method names that Blacklight calls in sequence when building a Solr query for search requests
  # Add filter_hidden_collections method to exclude collections hidden from catalog search
  self.default_processor_chain += [:filter_hidden_collections]

  # A Solr param filter that is NOT included by default in the chain,
  # but is appended by AdvancedController#index, to do a search
  # for facets _ignoring_ the current query, we want the facets
  # as if the current query weren't there.
  #
  # Also adds any solr params set in blacklight_config.advanced_search[:form_solr_parameters]
  def facets_for_advanced_search_form(solr_p)
    # ensure empty query is all records, to fetch available facets on entire corpus
    solr_p["q"]            = '{!lucene}*:*'
    # explicitly use lucene defType since we are passing a lucene query above (and appears to be required for solr 7)
    solr_p["defType"]      = 'lucene'
    # We only care about facets, we don't need any rows.
    solr_p["rows"]         = "0"

    # Anything set in config as a literal
    solr_p.merge!(blacklight_config.advanced_search[:form_solr_parameters]) if blacklight_config.advanced_search[:form_solr_parameters]
  end

  # Filter out collections that are marked as hidden from catalog search
  def filter_hidden_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    # Exclude collections that have hide_from_catalog_search set to true
    # Check both Collection (ActiveFedora) and CollectionResource (Valkyrie) models
    filter_query = '-(hide_from_catalog_search_bsi:true)'
    solr_parameters[:fq] << filter_query
  end
end
