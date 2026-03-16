# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to sort subcollections by title

module Hyrax
  module CollectionsControllerBehaviorDecorator
    def load_member_subcollections
      super
      return if @subcollection_docs.blank?

      @subcollection_docs.sort_by! { |doc| doc.title.first&.downcase }
    end

    def show
      params[:sort] ||= Hyrax::Collections::CollectionMemberSearchServiceDecorator::DEFAULT_SORT_FIELD

      super
    end
  end
end

Hyrax::CollectionsControllerBehavior.prepend Hyrax::CollectionsControllerBehaviorDecorator
