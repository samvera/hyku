# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  self.default_processor_chain += %i[add_advanced_parse_q_to_solr add_advanced_search_to_solr]
  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters
end
