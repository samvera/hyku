# frozen_string_literal: true

# a module to define abilities related to tenant management
# If using demo mode, we restrict access to tenant control management
# to only superadmins.
module Hyrax
  module Ability
    module TenantControlAbility
      def tenant_control_abilities
        if admin? && Site.account&.public_demo_tenant? != true
          can [:manage], :tenant_controls
        elsif tenant_superadmin?
          can [:manage], :tenant_controls
        else
          cannot [:manage], :tenant_controls
        end
      end
    end
  end
end
