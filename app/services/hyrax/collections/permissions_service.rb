# OVERRIDE FILE from Hyrax v2.9.0
#
# Override this class using #class_eval to avoid needing to copy the entire file over from
# the dependency. For more info, see the "Overrides using #class_eval" section in the README.
require_dependency Hyrax::Engine.root.join('app', 'services', 'hyrax', 'collections', 'permissions_service').to_s

Hyrax::Collections::PermissionsService.class_eval do
  # OVERRIDE: Add new method to check if a user has manage access to a collection.
  # This is used for :destroy permissions and the new :manage_discovery CanCan ability.
  # See Hyrax::Ability::CollectionAbility for usage.
  #
  # TODO: This just passes arguments to the private #manage_access_to_collection
  # method, which works and follows the Hyrax pattern, but it seems kind of silly
  # to have a whole method JUST for that... maybe make #manage_access_to_collection
  # public or use #send to call the private method directly?
  def self.can_manage_collection?(collection_id:, ability:)
    manage_access_to_collection?(collection_id: collection_id, ability: ability)
  end
end
