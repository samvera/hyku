# frozen_string_literal: true

# OVERRIDE: Hyrax 5.2.0 adds filesets to search to allow full text search results on the Collection show pages
module Hyrax
  module CollectionMemberSearchBuilderDecorator
    Hyrax::CollectionMemberSearchBuilder.default_processor_chain += [:show_works_or_works_that_contain_files]

    # These methods include the filesets in the search results
    def show_works_or_works_that_contain_files(solr_parameters)
      return if blacklight_params[:q].blank?
      solr_parameters[:user_query] = blacklight_params[:q]
      solr_parameters[:q] = new_query
      solr_parameters[:defType] = 'lucene'
    end

    # the {!lucene} gives us the OR syntax
    def new_query
      "{!lucene}#{interal_query(dismax_query)} #{interal_query(join_for_works_from_files)}"
    end

    # the _query_ allows for another parser (aka dismax)
    def interal_query(query_value)
      "_query_:\"#{query_value}\""
    end

    # the {!dismax} causes the query to go against the query fields
    def dismax_query
      "{!dismax v=$user_query}"
    end

    # join from file id to work relationship solrized file_set_ids_ssim
    def join_for_works_from_files
      "{!join from=#{Hyrax.config.id_field} to=member_ids_ssim}#{dismax_query}"
    end
  end
end

Hyrax::CollectionMemberSearchBuilder.prepend(Hyrax::CollectionMemberSearchBuilderDecorator)
