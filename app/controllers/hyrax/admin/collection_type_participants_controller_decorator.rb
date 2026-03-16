# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 make you can not delete the admin group
module Hyrax
  module Admin
    # Add backend validation to stop admin group access from being destroyed
    module CollectionTypeParticipantsControllerDecorator
      extend ActiveSupport::Concern

      included do
        # rubocop:disable Rails/LexicallyScopedActionFilter
        before_action :admin_group_participant_cannot_be_destroyed, only: :destroy
        # rubocop:enable Rails/LexicallyScopedActionFilter
      end

      def admin_group_participant_cannot_be_destroyed
        @collection_type_participant = Hyrax::CollectionTypeParticipant.find(params[:id])
        if @collection_type_participant.admin_group? &&
           @collection_type_participant.access == Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
          redirect_to(
            edit_admin_collection_type_path(
              @collection_type_participant.hyrax_collection_type_id,
              anchor: 'participants'
            ),
            alert: 'Admin group access cannot be removed'
          )
        end
      end
      private :admin_group_participant_cannot_be_destroyed
    end
  end
end

Hyrax::Admin::CollectionTypeParticipantsController.include(Hyrax::Admin::CollectionTypeParticipantsControllerDecorator)
