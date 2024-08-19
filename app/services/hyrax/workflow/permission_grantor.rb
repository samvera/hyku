# frozen_string_literal: true

module Hyrax
  module Workflow
    # The purpose of this service is to grant default workflow roles for admin set permission templates.
    #
    # This logic originally lived in the Hyrax::AdminSetCreateService, but was extracted and modified
    # to grant appropriate permissions for hyrax groups and users who have work roles.
    #
    # For usage:
    # @see Hyrax::AdminSetCreateService
    # @see RolesService
    class PermissionGrantor
      def self.grant_default_workflow_roles!(permission_template:, creating_user: nil)
        new(permission_template:, creating_user:).call
      end

      attr_accessor :permission_template, :creating_user

      def initialize(permission_template:, creating_user: nil)
        self.permission_template = permission_template
        self.creating_user = creating_user
      end

      def call
        # This code must be invoked before calling `Sipity::Role.all` or the managing,
        # approving, and depositing roles won't be there
        register_default_sipity_roles!

        ActiveRecord::Base.transaction do
          grant_all_workflow_roles_to_creating_user_and_admins!
          grant_workflow_roles_to_editors!
          grant_workflow_roles_to_depositors!
        end
      end

      private

      # Force creation of registered roles if they don't exist
      def register_default_sipity_roles!
        Sipity::Role[Hyrax::RoleRegistry::MANAGING]
        Sipity::Role[Hyrax::RoleRegistry::APPROVING]
        Sipity::Role[Hyrax::RoleRegistry::DEPOSITING]
      end

      def grant_all_workflow_roles_to_creating_user_and_admins!
        # The admin group should always receive workflow roles
        workflow_agents = [Hyrax::Group.find_by!(name: ::Ability.admin_group_name)]
        # The default admin set does not have a creating user
        workflow_agents << creating_user if creating_user
        workflow_agents |= Hyrax::Group.select { |g| g.site_role?(:admin) }.tap do |agent_list|
          ::User.find_each do |u|
            agent_list << u if u.has_role?(:admin, Site.instance)
          end

          grant_workflow_roles!(workflow_agents:, role_filters: nil)
        end

        grant_workflow_roles!(workflow_agents:, role_filters: nil)
      end

      def grant_workflow_roles_to_editors!
        editor_sipity_roles = [Hyrax::RoleRegistry::APPROVING, Hyrax::RoleRegistry::DEPOSITING]
        workflow_agents = Hyrax::Group.select { |g| g.site_role?(:work_editor) }.tap do |agent_list|
          ::User.find_each do |u|
            agent_list << u if u.has_role?(:work_editor, Site.instance)
          end
        end

        grant_workflow_roles!(workflow_agents:, role_filters: editor_sipity_roles)
      end

      def grant_workflow_roles_to_depositors!
        depositor_sipity_role = [Hyrax::RoleRegistry::DEPOSITING]
        workflow_agents = Hyrax::Group.select { |g| g.site_role?(:work_depositor) }.tap do |agent_list|
          ::User.find_each do |u|
            agent_list << u if u.has_role?(:work_depositor, Site.instance)
          end
        end

        grant_workflow_roles!(workflow_agents:, role_filters: depositor_sipity_role)
      end

      def grant_workflow_roles!(workflow_agents:, role_filters:)
        role_set = if role_filters.present?
                     Sipity::Role.select { |role| role_filters.include?(role.name) }
                   else
                     Sipity::Role.all
                   end

        permission_template.available_workflows.each do |workflow|
          role_set.each do |role|
            Hyrax::Workflow::PermissionGenerator.call(roles: role,
                                                      workflow:,
                                                      agents: workflow_agents)
          end
        end
      end
    end
  end
end
