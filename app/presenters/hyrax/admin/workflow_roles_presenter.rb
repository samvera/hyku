# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Expand to allow adding groups to workflow roles
module Hyrax
  module Admin
    # Displays a list of users and their associated workflow roles
    class WorkflowRolesPresenter
      def users
        ::User.registered
      end

      # OVERRIDE: New method for adding groups
      def groups
        Hyrax::Group.all
      end

      # OVERRIDE: New method for adding groups
      def group_presenter_for(group)
        agent = group.to_sipity_agent
        return unless agent
        AgentPresenter.new(agent)
      end

      def presenter_for(user)
        agent = user.sipity_agent
        return unless agent
        AgentPresenter.new(agent)
      end

      class AgentPresenter
        def initialize(agent)
          @agent = agent
        end

        def responsibilities_present?
          @agent.workflow_responsibilities.any?
        end

        def responsibilities
          @agent.workflow_responsibilities.each do |responsibility|
            yield ResponsibilityPresenter.new(responsibility)
          end
        end
      end

      class ResponsibilityPresenter
        def initialize(responsibility)
          @responsibility = responsibility
          @workflow_role_presenter = WorkflowRolePresenter.new(responsibility.workflow_role)
        end

        attr_accessor :responsibility

        delegate :label, to: :@workflow_role_presenter
      end
    end
  end
end
