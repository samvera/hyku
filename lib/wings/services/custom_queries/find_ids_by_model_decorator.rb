# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to use post instead of get for Solr requests
module Wings
  module Services
    module CustomQueries
      ##
      # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
      # @see Hyrax::CustomQueries::FindIdsByModel
      module FindIdsByModelDecorator
        ##
        # @note uses solr to do the lookup
        #
        # @param model [Class]
        # @param ids [Enumerable<#to_s>, Symbol]
        #
        # @return [Enumerable<Valkyrie::ID>]
        def find_ids_by_model(model:, ids: :all) # rubocop:disable Metrics/MethodLength
          return enum_for(:find_ids_by_model, model:, ids:) unless block_given?
          model_name = ModelRegistry.lookup(model).model_name

          solr_query = "_query_:\"{!raw f=has_model_ssim}#{model_name}\""
          solr_response = Hyrax::SolrService.post(solr_query, fl: 'id', rows: @query_rows)['response']

          loop do
            response_docs = solr_response['docs']
            response_docs.select! { |doc| ids.include?(doc['id']) } unless ids == :all

            response_docs.each { |doc| yield doc['id'] }

            break if (solr_response['start'] + solr_response['docs'].count) >= solr_response['numFound']
            solr_response = Hyrax::SolrService.post(
              solr_query,
              fl: 'id',
              rows: @query_rows,
              start: solr_response['start'] + @query_rows
            )['response']
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end

Wings::CustomQueries::FindIdsByModel.prepend Wings::Services::CustomQueries::FindIdsByModelDecorator
