# frozen_string_literal: true

module Hyrax
  module Collections
    # This decorator is used to override logic found in Hyrax v3.4.1
    #
    # This module is used to enable the Groups with Roles feature. It grants certain roles access to
    # either all AdminSets or all Collections (depending on the role) at create time.
    module PermissionsCreateServiceDecorator
      # This possible cruft before the #access_grants_attributes definition is how I (bkiahstroud) was
      # able to redefine a private class method using a decorator. If you know a better way,
      # please feel free to rework how this gets set up.
      def self.prepended(base)
        base.class_eval do
          class << self
            # @api private
            #
            # Gather the default permissions needed for a new collection
            #
            # @param collection_type [CollectionType] the collection type of the new collection
            # @param creating_user [User] the user that created the collection
            # @param grants [Array<Hash>] additional grants to apply to the new collection
            # @return [Array<Hash>] a hash containing permission attributes
            def access_grants_attributes(collection_type:, creating_user:, grants:)
              [
                { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
              ].tap do |attribute_list|
                # Grant manage access to the creating_user if it exists
                attribute_list << { agent_type: 'user', agent_id: creating_user.user_key, access: Hyrax::PermissionTemplateAccess::MANAGE } if creating_user
                # OVERRIDE BEGIN
                if collection_type.admin_set?
                  # Grant work roles appropriate access to all AdminSets
                  attribute_list << { agent_type: 'group', agent_id: 'work_depositor', access: Hyrax::PermissionTemplateAccess::DEPOSIT }
                  attribute_list << { agent_type: 'group', agent_id: 'work_editor', access: Hyrax::PermissionTemplateAccess::DEPOSIT }
                  attribute_list << { agent_type: 'group', agent_id: 'work_editor', access: Hyrax::PermissionTemplateAccess::VIEW }
                else
                  # Grant collection roles appropriate access to all Collections
                  attribute_list << { agent_type: 'group', agent_id: 'collection_editor', access: Hyrax::PermissionTemplateAccess::VIEW }
                  attribute_list << { agent_type: 'group', agent_id: 'collection_reader', access: Hyrax::PermissionTemplateAccess::VIEW }
                end
                attribute_list
                # OVERRIDE END
              end + managers_of_collection_type(collection_type: collection_type) + grants
            end
          end
        end
      end
    end
  end
end

Hyrax::Collections::PermissionsCreateService.prepend(Hyrax::Collections::PermissionsCreateServiceDecorator)
