# This file contains all overrides to dependencies required for Hyrax::Groups to have functional
# roles with permissions.
# TODO: Move all previous permissions-related overrides to this file

# Hyrax v2.9.0
Hyrax::CollectionSearchBuilder.class_eval do
  # OVERRIDE: Remove permission filters from solr queries
  # for users who should have discovery access to all Collections.
  def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
    # BEGIN override
    garc = GroupAwareRoleChecker.new(user: ability.current_user)
    return [] if garc.collection_manager? || garc.collection_editor? || garc.collection_reader?
    # END override
    return super unless permission_types.include?("deposit")

    ["{!terms f=id}#{collection_ids_for_deposit.join(',')}"]
  end
end

# Hyrax v2.9.0
Hyrax::Collections::PermissionsService.class_eval do
  # OVERRIDE: Add new method to check if a user has manage access to a collection.
  # This is used for :destroy permissions and the new :manage_discovery CanCan ability.
  # See Hyrax::Ability::CollectionAbility for usage.
  # TODO: This just passes arguments to the private #manage_access_to_collection
  # method, which works and follows the Hyrax pattern, but it seems kind of silly
  # to have a whole method JUST for that... maybe make #manage_access_to_collection
  # public or use #send to call the private method directly?
  def self.can_manage_collection?(collection_id:, ability:)
    manage_access_to_collection?(collection_id: collection_id, ability: ability)
  end
end
