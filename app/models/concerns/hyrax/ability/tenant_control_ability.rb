# frozen_string_literal: true

# a module to define abilities related to tenant management
# If using demo mode, we restrict access to tenant control management
# to only superadmins.
module Hyrax
  module Ability
    module TenantControlAbility
      def tenant_control_abilities
        if admin? && !public_demo_tenant?
          can [:manage], :tenant_controls
        elsif tenant_superadmin?
          can [:manage], :tenant_controls
        else
          cannot [:manage], :tenant_controls
        end

        user_invite_abilities
      end

      # Inviting users is a tenant control on a public demo tenant. That flag
      # means the admin credential is published to visitors, so an admin there
      # is not a trusted operator and must not be able to send mail from the
      # tenant's domain to addresses of their choosing. The tenant's superadmin
      # still can.
      #
      # On a standard tenant this leaves :invite where UserAbility and
      # admin_permissions put it, so behavior is unchanged.
      def user_invite_abilities
        can :invite, User if tenant_superadmin?

        cannot :invite, User if public_demo_tenant? && !tenant_superadmin? && !superadmin?
      end

      private

      def public_demo_tenant?
        Site.account&.public_demo_tenant? == true
      end
    end
  end
end
