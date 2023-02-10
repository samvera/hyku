# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Alter abilities for Groups with Roles feature
module Hyrax
  module Ability
    module CollectionAbility
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/AbcSize
      def collection_abilities
        models = [Hyrax::PcdmCollection, Hyrax.config.collection_class].uniq
        if admin?
          models.each do |collection_model|
            can :manage, collection_model
            can :manage_any, collection_model
            can :create_any, collection_model
            can :view_admin_show_any, collection_model
          end
        else
          models.each { |collection_model| can :manage_any, collection_model } if
            Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)

          models.each { |collection_model| can :create_any, collection_model } if
            Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)

          models.each { |collection_model| can :view_admin_show_any, collection_model } if
          Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)

          # OVERRIDE: remove :destroy -- users who only have edit access cannot destroy
          models.each do |collection_model|
            can [:edit, :update], collection_model do |collection|
              test_edit(collection.id)
            end

            can :view_admin_show, collection_model do |collection| # admin show page
              Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(
                ability: self,
                collection_id: collection.id
              )
            end

            can :view_admin_show, ::SolrDocument do |solr_doc| # admin show page
              Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(
                ability: self,
                collection_id: solr_doc.id
              ) # checks collections and admin_sets
            end

            can :read, collection_model do |collection| # public show page
              test_read(collection.id)
            end

            can :deposit, collection_model do |collection|
              Hyrax::Collections::PermissionsService.can_deposit_in_collection?(
                ability: self,
                collection_id: collection.id
              )
            end
            # OVERRIDE: add rules -- only users who have manage access can destroy
            can :destroy, collection_model do |collection|
              Hyrax::Collections::PermissionsService.can_manage_collection?(ability: self, collection_id: collection.id)
            end
            can :destroy, ::SolrDocument do |solr_doc|
              if solr_doc.collection?
                Hyrax::Collections::PermissionsService.can_manage_collection?(
                  ability: self,
                  collection_id: solr_doc.id
                )
              end
            end

            can :deposit, ::SolrDocument do |solr_doc|
              Hyrax::Collections::PermissionsService.can_deposit_in_collection?(
                ability: self,
                collection_id: solr_doc.id
              ) # checks collections and admin_sets
            end

            # OVERRIDE: add ability to restrict who can change a Collection's discovery setting
            can :manage_discovery, collection_model do |collection| # Discovery tab on edit form
              Hyrax::Collections::PermissionsService.can_manage_collection?(
                ability: self,
                collection_id: collection.id
              )
            end

            # OVERRIDE: add ability to restrict who can add works and subcollections to /
            # remove works and subcollections from a Collection
            can :manage_items_in_collection, collection_model do |collection|
              Hyrax::Collections::PermissionsService.can_manage_collection?(ability: self, collection_id: collection.id)
            end
            can :manage_items_in_collection, ::SolrDocument do |solr_doc|
              Hyrax::Collections::PermissionsService.can_manage_collection?(
                ability: self,
                collection_id: solr_doc.id
              )
            end
            can :manage_items_in_collection, ::String do |id|
              Hyrax::Collections::PermissionsService.can_manage_collection?(ability: self, collection_id: id)
            end
          end
          # "Undo" permission restrictions added by the Groups with Roles feature,
          # effectively reverting them back to default Hyrax behavior
          unless ActiveModel::Type::Boolean.new.cast(
            ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
          )
            can %i[destroy manage_discovery manage_items_in_collection], Hyrax::PcdmCollection do |collection|
              test_edit(collection.id)
            end
          end
        end
      end

      # OVERRIDE: Add abilities for collection roles. These apply to all Collections within a tenant.
      # Permissions are overwritten if given explicit access; e.g. if a collection reader is added
      # as a manager of a Collection, they should be able to manage that Collection.
      def collection_roles
        # Can create, read, edit/update, destroy, and change visibility (discovery) of all Collections
        models = [Hyrax::PcdmCollection, Hyrax.config.collection_class].uniq
        if collection_manager?
          models.each do |collection_model|
            # Permit all actions (same collection permissions as admin users)
            can :manage, collection_model
            can :manage, ::SolrDocument, &:collection?
            can :manage, ::String do |id|
              doc = permissions_doc(id)
              doc.collection?
            end
            can :create_collection_type, CollectionType
          end
        # Can create, read, and edit/update all Collections
        elsif collection_editor?
          models.each { |collection_model| can %i[edit update create create_any], collection_model }
          can %i[edit update], ::SolrDocument, &:collection?
          can %i[edit update], ::String do |id|
            doc = permissions_doc(id)
            doc.collection?
          end
          models.each { |collection_model| can %i[read read_any view_admin_show view_admin_show_any], collection_model }
          can %i[read read_any view_admin_show view_admin_show_any], ::SolrDocument, &:collection?
          can %i[read read_any view_admin_show view_admin_show_any], ::String do |id|
            doc = permissions_doc(id)
            doc.collection?
          end
          can :create_collection_type, CollectionType

        # Can read all Collections
        elsif collection_reader?
          models.each { |collection_model| can %i[read read_any view_admin_show view_admin_show_any], collection_model }
          can %i[read read_any view_admin_show view_admin_show_any], ::SolrDocument, &:collection?
          can %i[read read_any view_admin_show view_admin_show_any], ::String do |id|
            doc = permissions_doc(id)
            doc.collection?
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
