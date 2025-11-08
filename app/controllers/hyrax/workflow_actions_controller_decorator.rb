# frozen_string_literal: true

# OVERRIDE Hyrax 5.2.0 to redirect back to the review submissions page after approving or rejecting a work
# when the user came from the review submissions page

module Hyrax
  module WorkflowActionsControllerDecorator
    private

    def after_update_response
      respond_to do |wants|
        redirect_path = session[:from_admin_workflows] ? admin_workflows_path : [main_app, curation_concern]
        wants.html { redirect_to redirect_path, notice: "The #{curation_concern.class.human_readable_type} has been updated." }
        wants.json { render 'hyrax/base/show', status: :ok, location: polymorphic_path([main_app, curation_concern]) }
      end
    end
  end
end

Hyrax::WorkflowActionsController.prepend(Hyrax::WorkflowActionsControllerDecorator)
