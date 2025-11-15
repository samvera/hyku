# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Expand to allow adding groups to workflow roles

module Hyrax
  module Admin
    # Displays a list of users and their associated workflow roles
    module WorkflowRolesPresenterDecorator
      # OVERRIDE: New method for adding groups
      def groups
        Hyrax::Group.all
      end

      # OVERRIDE: New method for adding groups
      def group_presenter_for(group)
        agent = group.to_sipity_agent
        return unless agent
        Hyrax::Admin::WorkflowRolesPresenter::AgentPresenter.new(agent)
      end
    end
  end
end

Hyrax::Admin::WorkflowRolesPresenter.prepend(Hyrax::Admin::WorkflowRolesPresenterDecorator)
