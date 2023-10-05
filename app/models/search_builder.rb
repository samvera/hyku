# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder
  include BlacklightAdvancedSearch::AdvancedSearchBuilder
  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  self.default_processor_chain += %i[add_advanced_parse_q_to_solr add_advanced_search_to_solr]
end
