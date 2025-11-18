# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Grants certain roles access to either all AdminSets or
#                          all Collections (depending on the role) at create time.
module Hyrax
  module Collections
    module PermissionsCreateServiceDecorator
      # @api private
      #
      # Gather the default permissions needed for a new collection
      #
      # @param collection_type [CollectionType] the collection type of the new collection
      # @param creating_user [User] the user that created the collection
      # @param grants [Array<Hash>] additional grants to apply to the new collection
      # @return [Array<Hash>] a hash containing permission attributes
      # rubocop:disable Metrics/MethodLength
      def access_grants_attributes(collection_type:, creating_user:, grants:)
        # rubocop:enable Metrics/MethodLength
        [ # rubocop:disable Metrics/BlockLength
          { agent_type: 'group', agent_id: admin_group_name, access: Hyrax::PermissionTemplateAccess::MANAGE }
        ].tap do |attribute_list|
          # Grant manage access to the creating_user if it exists
          if creating_user
            attribute_list << {
              agent_type: 'user',
              agent_id: creating_user.user_key,
              access: Hyrax::PermissionTemplateAccess::MANAGE
            }
          end
          # OVERRIDE BEGIN
          if collection_type.admin_set?
            # Grant work roles appropriate access to all AdminSets
            attribute_list << {
              agent_type: 'group',
              agent_id: 'work_depositor',
              access: Hyrax::PermissionTemplateAccess::DEPOSIT
            }
            attribute_list << {
              agent_type: 'group',
              agent_id: 'work_editor',
              access: Hyrax::PermissionTemplateAccess::DEPOSIT
            }
            attribute_list << {
              agent_type: 'group',
              agent_id: 'work_editor',
              access: Hyrax::PermissionTemplateAccess::VIEW
            }
          else
            # Grant collection roles appropriate access to all Collections
            attribute_list << {
              agent_type: 'group',
              agent_id: 'collection_editor',
              access: Hyrax::PermissionTemplateAccess::VIEW
            }
            attribute_list << {
              agent_type: 'group',
              agent_id: 'collection_reader',
              access: Hyrax::PermissionTemplateAccess::VIEW
            }
          end
          # rubocop:disable Lint/Void
          attribute_list
          # rubocop:enable Lint/Void
          # OVERRIDE END
        end + managers_of_collection_type(collection_type:) + grants
      end
      private :access_grants_attributes
    end
  end
end

# This pattern is required for overriding an existing class method
Hyrax::Collections::PermissionsCreateService
  .singleton_class
  .send(:prepend, Hyrax::Collections::PermissionsCreateServiceDecorator)
