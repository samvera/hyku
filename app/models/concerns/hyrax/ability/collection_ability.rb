# OVERRIDE FILE from Hyrax 2.5.1 - Edit existing / add additional abilities
module Hyrax
  module Ability
    module CollectionAbility
      def collection_abilities # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        if admin?
          can :manage, Collection
          can :manage_any, Collection
          can :create_any, Collection
          can :view_admin_show_any, Collection
        else
          can :manage_any, Collection if Hyrax::Collections::PermissionsService.can_manage_any_collection?(ability: self)
          can :create_any, Collection if Hyrax::CollectionTypes::PermissionsService.can_create_any_collection_type?(ability: self)
          can :view_admin_show_any, Collection if Hyrax::Collections::PermissionsService.can_view_admin_show_for_any_collection?(ability: self)

          # OVERRIDE: remove :destroy -- users who only have edit access cannot destroy
          can [:edit, :update], Collection do |collection| # for test by solr_doc, see solr_document_ability.rb
            test_edit(collection.id)
          end

          # OVERRIDE: add rules -- only users who have manage access can destroy
          can :destroy, Collection do |collection|
            Hyrax::Collections::PermissionsService.can_manage_collection?(ability: self, collection_id: collection.id)
          end
          # TODO: make sure this does not apply to AdminSet solr documents -- this should be handled in admin_set_ability.rb
          can :destroy, ::SolrDocument do |solr_doc|
            Hyrax::Collections::PermissionsService.can_manage_collection?(ability: self, collection_id: solr_doc.id)
          end

          can :deposit, Collection do |collection|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: collection.id)
          end
          can :deposit, ::SolrDocument do |solr_doc|
            Hyrax::Collections::PermissionsService.can_deposit_in_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can :view_admin_show, Collection do |collection| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: collection.id)
          end
          can :view_admin_show, ::SolrDocument do |solr_doc| # admin show page
            Hyrax::Collections::PermissionsService.can_view_admin_show_for_collection?(ability: self, collection_id: solr_doc.id) # checks collections and admin_sets
          end

          can :read, Collection do |collection| # public show page  # for test by solr_doc, see solr_document_ability.rb
            test_read(collection.id)
          end

          # OVERRIDE: add ability to restrict who can change a Collection's discovery setting
          can :manage_discovery, Collection do |collection| # Discovery tab on edit form
            Hyrax::Collections::PermissionsService.can_manage_collection?(ability: self, collection_id: collection.id)
          end
        end
      end

      # OVERRIDE: Add abilities for collection roles. These apply to all Collections within a tenant.
      # Permissions are overwritten if given explicit access; e.g. if a collection reader is added
      # as a manager of a Collection, they should be able to manage that Collection.
      def collection_roles
        # Can create, read, edit/update, destroy, and change visibility (discovery) of all Collections
        if group_aware_role_checker.collection_manager?
          # Permit all actions (same collection permissions as admin users)
          can :manage, Collection
          can :manage, ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end

        # Can create, read, and edit/update all Collections
        elsif group_aware_role_checker.collection_editor?
          can %i[edit update create create_any], Collection
          can %i[edit update], ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end
          can %i[read read_any view_admin_show view_admin_show_any], Collection
          can %i[read read_any view_admin_show view_admin_show_any], ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end

        # Can read all Collections
        elsif group_aware_role_checker.collection_reader?
          can %i[read read_any view_admin_show view_admin_show_any], Collection
          can %i[read read_any view_admin_show view_admin_show_any], ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end
        end
      end
    end
  end
end
