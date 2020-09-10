# Override from hyrax 2.5.1 to add groups to workflow roles
module Sipity
  # A proxy for something that can take an action.
  #
  # * A User can be an agent
  # * A Group can be an agent (though Group is outside the scope of this system)
  class Agent < ActiveRecord::Base
    self.table_name = 'sipity_agents'

    ENTITY_LEVEL_AGENT_RELATIONSHIP = 'entity_level'.freeze
    WORKFLOW_LEVEL_AGENT_RELATIONSHIP = 'workflow_level'.freeze

    has_many :workflow_responsibilities, dependent: :destroy, class_name: 'Sipity::WorkflowResponsibility'
    has_many :entity_specific_responsibilities, dependent: :destroy, class_name: 'Sipity::EntitySpecificResponsibility'

    has_many :comments,
             foreign_key: :agent_id,
             dependent: :destroy,
             class_name: 'Sipity::Comment'

    # TODO: uncomment line 22, delete lines
    # belongs_to :proxy_for, polymorphic: true

    def proxy_for=(target)
      self.proxy_for_id = target.id
      self.proxy_for_type = target.class.name
    end

    def proxy_for
      @proxy_for ||= proxy_for_type.constantize.find(proxy_for_id)
    end

    # Override from hyrax 2.5.1 to add group responsibilities to users
    def workflow_responsibilities
      groups = if proxy_for.respond_to?(:roles) && !proxy_for_type.match("Hyrax::Group")
        proxy_for.roles.where(name: "member", resource_type: "Hyrax::Group").map(&:resource)
      end
      if groups
        group_workflow_responsibilities = groups.map{ |g| g.to_sipity_agent.workflow_responsibilities }.flatten
        super.or(Sipity::WorkflowResponsibility.where(id: group_workflow_responsibilities))
      else
        super
      end
    end
  end
end
