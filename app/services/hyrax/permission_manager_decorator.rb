# frozen_string_literal: true

module Hyrax
  # This decorator is used to override logic found in Hyrax v5.0.0rc2
  #
  # Because Hyku has converted the Hyrax::Group model from a PORO to a db-backed active record object,
  # we have to query for existing Hyrax groups instead of initializing empty ones.
  #
  # Also, by default in Hyrax, permissions can only be assigned to Groups or Users. Hyku has extended
  # that to include the Role model as part of the Groups with Roles feature, but Hyrax permissions
  # don't have any conception of what Role is, so Hyrax permissions consider Role permissions functionally
  # identical to Group permissions.
  #
  # In techincial terms, the :agent_type of Role permissions is the same as it is for Groups.
  #
  # Because of this, we also add queries for Role permissions in addition to Group permissions
  # as part of these overrides.
  module PermissionManagerDecorator
    # NOTE: The fallback to Group.new for special groups is necessary due to a fundamental
    #       change in between behavior in Valkyrie models vs ActiveFedora models. In
    #       "public" groups now go through the access_control_list module, and
    #       the group gets assigned to the objects here. Because Hyku persists
    #       groups and "public" is not a real group, this errored because the group was
    #       not found. We have added a fallback to handle it like Hyrax does. In case
    #       of permission errors, this is a point to investigate.
    SPECIAL_GROUPS = ["public"].freeze

    private

    # rubocop:disable Metrics/MethodLength
    def update_groups_for(mode:, groups:)
      groups = groups.map(&:to_s)

      acl.permissions.each do |permission|
        next unless permission.mode.to_sym == mode
        next unless permission.agent.starts_with?(Hyrax::Group.name_prefix)

        group_name = permission.agent.gsub(Hyrax::Group.name_prefix, '')
        next if groups.include?(group_name)

        # OVERRIDE:
        group_or_role = group_or_role(name: group_name)
        next unless group_or_role
        acl.revoke(mode).from(group_or_role)
      end

      groups.each do |g|
        # OVERRIDE:
        group_or_role = group_or_role(name: g)
        next unless group_or_role
        acl.grant(mode).to(group_or_role)
      end
    end
    # rubocop:enable Metrics/MethodLength

    # OVERRIDE:
    #   - Replace Group#new with Group#find_by(:name)
    #   - Add fallback on Role, which has the same agent_type as Group
    #   - Fallback to Group.new() for "public" but don't save group
    def group_or_role(name:)
      group_or_role = Group.find_by(name:) || Role.find_by(name:)
      return group_or_role if group_or_role
      return Group.new(name:) if SPECIAL_GROUPS.include?(name)
      nil
    end
  end
end

Hyrax::PermissionManager.prepend(Hyrax::PermissionManagerDecorator)
