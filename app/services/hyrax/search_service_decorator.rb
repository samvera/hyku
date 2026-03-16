# frozen_string_literal: true

# OVERRIDE Hyrax 5.2.0 to add custom sort fields

module Hyrax
  module SearchServiceDecorator
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def search_results
      builder = search_builder.with(user_params)
      builder.page = user_params[:page] if user_params[:page]
      builder.rows = (user_params[:per_page] || user_params[:rows]) if user_params[:per_page] || user_params[:rows]

      builder = yield(builder) if block_given?
      # OVERRIDE: without this merge, Blightlight seems to ignore the sort params on Collections
      builder.merge(sort: user_params[:sort]) if user_params[:sort]
      response = repository.search(builder)

      if response.grouped? && grouped_key_for_results
        [response.group(grouped_key_for_results), []]
      elsif response.grouped? && response.grouped.length == 1
        [response.grouped.first, []]
      else
        [response, response.documents]
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end

Hyrax::SearchService.prepend Hyrax::SearchServiceDecorator
