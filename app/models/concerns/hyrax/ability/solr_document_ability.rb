# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.2 Alter abilities for Groups with Roles feature
module Hyrax
  module Ability
    module SolrDocumentAbility
      def solr_document_abilities
        if admin?
          can [:manage], ::SolrDocument
        else
          # OVERRIDE: remove :destroy -- only users with manage access can destroy
          can [:edit, :update], ::SolrDocument do |solr_doc|
            test_edit(solr_doc.id)
          end
          can :read, ::SolrDocument do |solr_doc|
            test_read(solr_doc.id)
          end

          # "Undo" permission restrictions added by the Groups with Roles feature,
          # effectively reverting them back to default Hyrax behavior
          unless ActiveModel::Type::Boolean.new.cast(
            ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
          )
            can :destroy, ::SolrDocument do |solr_doc|
              test_edit(solr_doc.id)
            end
          end
        end
      end
    end
  end
end
