# frozen_string_literal: true

module Hyrax
  module Forms
    module Admin
      # Filter Collection Roles out of displayed access grants
      module CollectionTypeFormDecorator
        # Add new method to filter out collection_type_participants for Collection Roles in the UI. We do this
        # because collection_type_participants for Collection Roles should never be allowed to be removed.
        def filter_participants_by_access(access)
          filtered_participants = collection_type_participants.select(&access)
          filtered_participants.reject! { |ag| ::RolesService::COLLECTION_ROLES.include?(ag.agent_id) }

          filtered_participants || []
        end
      end
    end
  end
end

Hyrax::Forms::Admin::CollectionTypeForm.include(Hyrax::Forms::Admin::CollectionTypeFormDecorator)
