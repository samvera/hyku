# frozen_string_literal: true

# OVERRIDE Hyrax 5.3.0 to keep the graph filters out of Solr's filter cache, which intermittently 500s with "Recursive update"
module Hyrax
  module Dashboard
    module NestedCollectionsSearchBuilderDecorator
      def show_only_other_collections_of_the_same_collection_type(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
          Hyrax::SolrQueryBuilderService.construct_query(Hyrax.config.collection_type_index_field => @collection.collection_type_gid),
          "-{!graph cache=false from=id to=member_of_collection_ids_ssim#{' maxDepth=1' if @nest_direction == :as_parent}}id:#{@collection.id}",
          "-{!graph cache=false to=id from=member_of_collection_ids_ssim#{' maxDepth=1' if @nest_direction == :as_child}}id:#{@collection.id}"
        ]
      end
    end
  end
end

Hyrax::Dashboard::NestedCollectionsSearchBuilder.prepend(Hyrax::Dashboard::NestedCollectionsSearchBuilderDecorator)
