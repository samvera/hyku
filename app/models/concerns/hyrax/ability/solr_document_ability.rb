# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Alter abilities for Groups with Roles feature
module Hyrax
  module Ability
    module SolrDocumentAbility
      # rubocop:disable Metrics/MethodLength
      def solr_document_abilities
        if admin?
          can [:manage], ::SolrDocument
        else
          # OVERRIDE: remove :destroy -- only users with manage access can destroy This is brought
          # about by the permission restrictions added by the Groups with Roles feature,
          can [:edit, :update], ::SolrDocument do |solr_doc|
            test_edit(solr_doc.id)
          end
          can :read, ::SolrDocument do |solr_doc|
            test_read(solr_doc.id)
          end

          # To "Undo" the above override (e.g. return to default Hyrax behavior) set the below ENV.
          unless ActiveModel::Type::Boolean.new.cast(
            ENV.fetch('HYKU_RESTRICT_CREATE_AND_DESTROY_PERMISSIONS', nil)
          )
            can :destroy, ::SolrDocument do |solr_doc|
              test_edit(solr_doc.id)
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
