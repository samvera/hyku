# frozen_string_literal: true
# TODO(bkiahstroud): filename and location make sense?
module Hyrax
  module GroupsService
    ##
    # NOTE: DO NOT CHANGE THE NAMES OF THESE GROUPS!
    # They are required to exist for permissions to work properly.
    # TODO(bkiahstroud): Grab list from Hyrax::RoleRegistry instead? See AdminSetCreateService
    ALL_DEFAULT_GROUPS_WITH_ROLES = {
      'admin' => [:admin],
      'registered' => [],
      'managing' => [:tenant_manager, :collection_manager]
    }.freeze

    class << self
      # TODO(bkiahstroud): add default descriptions using i18n
      def create_default_hyrax_groups!
        ALL_DEFAULT_GROUPS_WITH_ROLES.each do |group_name, group_roles|
          group = Hyrax::Group.find_or_create_by!(name: group_name)

          group_roles.each do |role_name|
            next if role_name.blank?

            group.roles |= [Role.find_by!(name: role_name)]
          end
        end
      end
    end
  end
end
