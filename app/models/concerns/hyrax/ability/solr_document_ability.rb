# NOTE(bkiahstroud): Override file from Hyrax 2.5.1
module Hyrax
  module Ability
    module SolrDocumentAbility
      def solr_document_abilities
        if admin?
          can [:manage], ::SolrDocument
        else
          # OVERRIDE: remove :destroy -- users who only have edit access cannot destroy
          # TODO: make sure depositors can still delete their own works
          can [:edit, :update], ::SolrDocument do |solr_doc|
            test_edit(solr_doc.id)
          end
          can :read, ::SolrDocument do |solr_doc|
            test_read(solr_doc.id)
          end
        end
      end
    end
  end
end
