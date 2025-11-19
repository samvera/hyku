# frozen_string_literal: true

# OVERRIDE Hyrax 5.2.0 to redirect back to the review submissions page after approving or rejecting a work
# when the user came from the review submissions page

module Hyrax
  module Admin
    module WorkflowsControllerDecorator
      def index
        super
        session[:from_admin_workflows] = true if request.fullpath.include?(admin_workflows_path)
      end
    end
  end
end

Hyrax::Admin::WorkflowsController.prepend(Hyrax::Admin::WorkflowsControllerDecorator)
