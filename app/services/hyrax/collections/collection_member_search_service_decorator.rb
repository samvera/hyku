# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to sort subcollections by title
module Hyrax
  module Collections
    module CollectionMemberSearchServiceDecorator
      DEFAULT_SORT_FIELD = 'title_ssi asc'

      def available_member_works
        sort_field = user_params[:sort] || DEFAULT_SORT_FIELD
        response, _docs = search_results do |builder|
          builder.search_includes_models = :works
          builder.merge(sort: sort_field)
          builder
        end
        response
      end
    end
  end
end

Hyrax::Collections::CollectionMemberSearchService.prepend Hyrax::Collections::CollectionMemberSearchServiceDecorator
