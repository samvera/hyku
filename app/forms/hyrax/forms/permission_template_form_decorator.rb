# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.1 to fix Hyrax::Groups args

module Hyrax
  module Forms
    module PermissionTemplateFormDecorator
      # @return [Array<Sipity::Agent>] a list sipity agents extracted from attrs
      def agents_from_attributes
        grants_as_collection.map do |grant|
          agent = if grant[:agent_type] == 'user'
                    ::User.find_by_user_key(grant[:agent_id])
                  else
                    Hyrax::Group.new(name: grant[:agent_id])
                  end
          Sipity::Agent(agent)
        end
      end

      # @return [Array<Sipity::Agent>] a list of sipity agents corresponding to
      # the manager role of the permission_template
      def manager_agents
        @manager_agents ||= begin
          authorized_agents = manager_grants.map do |access|
            if access.agent_type == 'user'
              ::User.find_by_user_key(access.agent_id)
            else
              Hyrax::Group.new(name: access.agent_id)
            end
          end

          authorized_agents.map { |agent| Sipity::Agent(agent) }
        end
      end
    end
  end
end

Hyrax::Forms::PermissionTemplateForm.prepend(Hyrax::Forms::PermissionTemplateFormDecorator)
