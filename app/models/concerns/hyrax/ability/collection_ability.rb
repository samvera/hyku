# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 Alter abilities for Groups with Roles feature
module Hyrax
  module Ability
    # rubocop:disable Metrics/ModuleLength
    module CollectionAbility
      def collection_models
        @collection_models ||= ["::Collection".safe_constantize, Hyrax::PcdmCollection, Hyrax.config.collection_class].uniq
      end

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Metrics/CyclomaticComplexity
      def collection_abilities
        if admin?
          can :manage, collection_models
          can :manage_any, collection_models
          can :create_any, collection_models
          can :view_admin_show_any, collection_models
        else
          can :manage_any, collection_models if Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)

          can :create_any, collection_models if Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)

          can :view_admin_show_any, collection_models if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)

          # OVERRIDE: remove :destroy -- users who only have edit access cannot destroy
          can [:edit, :update], collection_models do |collection|
            test_edit(collection.id.to_s)
          end

          can :view_admin_show, collection_models do |collection| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(
              ability: self,
              collection_id: collection.id.to_s
            )
          end

          can :view_admin_show, ::SolrDocument do |solr_doc| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(
              ability: self,
              collection_id: solr_doc.id.to_s
            ) # checks collections and admin_sets
          end

          can :read, collection_models do |collection| # public show page
            test_read(collection.id.to_s)
          end

          can :deposit, collection_models do |collection|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(
              ability: self,
              collection_id: collection.id.to_s
            )
          end

          # OVERRIDE: add rules -- only users who have manage access can destroy
          can :destroy, collection_models do |collection|
            Hyrax::Collections::PermissionsService.manage_access_to_collection?(ability: self, collection_id: collection.id.to_s)
          end

          # OVERRIDE: add ability to restrict who can change a Collection's discovery setting
          can :manage_discovery, collection_models do |collection| # Discovery tab on edit form
            Hyrax::Collections::PermissionsService.manage_access_to_collection?(
              ability: self,
              collection_id: collection.id.to_s
            )
          end

          # OVERRIDE: add ability to restrict who can add works and subcollections to /
          # remove works and subcollections from a Collection
          can :manage_items_in_collection, collection_models do |collection|
            Hyrax::Collections::PermissionsService.manage_access_to_collection?(ability: self, collection_id: collection.id.to_s)
          end

          can :manage_items_in_collection, ::SolrDocument do |solr_doc|
            Hyrax::Collections::PermissionsService.manage_access_to_collection?(
              ability: self,
              collection_id: solr_doc.id.to_s
            )
          end

          can :manage_items_in_collection, [::String, Valkyrie::ID] do |id|
            Hyrax::Collections::PermissionsService.manage_access_to_collection?(ability: self, collection_id: id.to_s)
          end

          can :destroy, ::SolrDocument do |solr_doc|
            if solr_doc.collection?
              Hyrax::Collections::PermissionsService.manage_access_to_collection?(
                ability: self,
                collection_id: solr_doc.id.to_s
              )
            end
          end

          can :deposit, ::SolrDocument do |solr_doc|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(
              ability: self,
              collection_id: solr_doc.id.to_s
            ) # checks collections and admin_sets
          end

          # "Undo" permission restrictions added by the Groups with Roles feature,
          # effectively reverting them back to default Hyrax behavior
          unless ActiveModel::Type::Boolean.new.cast(
            ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
          )
            can %i[destroy manage_discovery manage_items_in_collection], collection_models do |collection|
              test_edit(collection.id.to_s)
            end
          end
        end
      end

      # OVERRIDE: Add abilities for collection roles. These apply to all Collections within a tenant.
      # Permissions are overwritten if given explicit access; e.g. if a collection reader is added
      # as a manager of a Collection, they should be able to manage that Collection.
      def collection_roles
        if collection_manager?
          # Permit all actions (same collection permissions as admin users)
          can :manage, collection_models
          can :manage, ::SolrDocument, &:collection?
          can :manage, [::String, Valkyrie::ID] do |id|
            doc = permissions_doc(id.to_s)
            doc.collection?
          end
          can :create_collection_type, CollectionType
        # Can create, read, and edit/update all Collections
        elsif collection_editor?
          can %i[edit update create create_any], collection_models
          can %i[edit update], ::SolrDocument, &:collection?
          can %i[edit update], [::String, Valkyrie::ID] do |id|
            doc = permissions_doc(id.to_s)
            doc.collection?
          end
          can %i[read read_any view_admin_show view_admin_show_any], collection_models
          can %i[read read_any view_admin_show view_admin_show_any], ::SolrDocument, &:collection?
          can %i[read read_any view_admin_show view_admin_show_any], [::String, Valkyrie::ID] do |id|
            doc = permissions_doc(id.to_s)
            doc.collection?
          end
          can :create_collection_type, CollectionType

        # Can read all Collections
        elsif collection_reader?
          can %i[read read_any view_admin_show view_admin_show_any], collection_models
          can %i[read read_any view_admin_show view_admin_show_any], ::SolrDocument, &:collection?
          can %i[read read_any view_admin_show view_admin_show_any], [::String, Valkyrie::ID] do |id|
            doc = permissions_doc(id.to_s)
            doc.collection?
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/PerceivedComplexity
      # rubocop:enable Metrics/CyclomaticComplexity
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
