# frozen_string_literal: true

module Hyrax
  module Forms
    class WorkflowResponsibilityGroupForm
      def initialize(params = {})
        model_instance.workflow_role_id = params[:workflow_role_id]
        return unless params[:group_id]
        group = Hyrax::Group.find(params[:group_id])
        model_instance.agent = group.to_sipity_agent
      end

      ##
      # This method is necessary for the HTML form fields to have the correct name (e.g. `<input
      # name="sipity_workflow_responsibility[group_id]">`).
      #
      # @see ActiveModel::Naming
      def model_instance
        @model ||= Sipity::WorkflowResponsibility.new
      end

      delegate :model_name, :to_key, :workflow_role_id, :persisted?, :save!, to: :model_instance

      def group_id
        nil
      end

      def group_options
        Hyrax::Group.all
      end

      # The select options for choosing a responsibility sorted by label
      def workflow_role_options
        options = Sipity::WorkflowRole.all.map do |wf_role|
          [Hyrax::Admin::WorkflowRolePresenter.new(wf_role).label, wf_role.id]
        end
        options.sort_by(&:first)
      end
    end
  end
end
