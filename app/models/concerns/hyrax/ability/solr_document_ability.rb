# NOTE(bkiahstroud): Override file from Hyrax 2.5.1
module Hyrax
  module Ability
    module SolrDocumentAbility
      def solr_document_abilities
        if admin?
          can [:manage], ::SolrDocument

        elsif collection_manager?
          can [:manage, :manage_any, :create_any, :view_admin_show_any], ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end

        elsif collection_editor?
          can [:manage, :deposit, :view_admin_show, :view_admin_show_any], ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end
          cannot :destroy, ::SolrDocument

        elsif collection_reader?
          cannot :manage, ::SolrDocument
          can [:read, :read_any, :view_admin_show, :view_admin_show_any], ::SolrDocument do |solr_doc|
            solr_doc.collection?
          end

        else
          can [:edit, :update, :destroy], ::SolrDocument do |solr_doc|
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
