# frozen_string_literal: true

# OVERRIDE FILE from Hyrax v3.4.2
require_dependency Hyrax::Engine.root.join('app', 'presenters', 'hyrax', 'admin', 'workflow_roles_presenter').to_s

Hyrax::Admin::WorkflowRolesPresenter.class_eval do
  # OVERRIDE: Add new method to add new method to add groups
  def group_presenter_for(group)
    agent = group.to_sipity_agent
    return unless agent
    AgentPresenter.new(agent)
  end
end
