# frozen_string_literal: true

# OVERRIDE FILE from Hryax v2.9.0
require_dependency Hyrax::Engine.root.join('app', 'controllers', 'hyrax', 'admin', 'collection_type_participants_controller').to_s

Hyrax::Admin::CollectionTypeParticipantsController.class_eval do
  before_action :admin_group_participant_cannot_be_destroyed, only: :destroy

  # OVERRIDE: add backend validation to stop admin group access from being destroyed
  def admin_group_participant_cannot_be_destroyed
    @collection_type_participant = Hyrax::CollectionTypeParticipant.find(params[:id])
    if @collection_type_participant.admin_group? && @collection_type_participant.access == Hyrax::CollectionTypeParticipant::MANAGE_ACCESS
      redirect_to(
        edit_admin_collection_type_path(@collection_type_participant.hyrax_collection_type_id, anchor: 'participants'),
        alert: 'Admin group access cannot be removed'
      )
    end
  end
  private :admin_group_participant_cannot_be_destroyed
end
