# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceIndexer < Hyrax::Indexers::PcdmCollectionIndexer
  include Hyrax::Indexer(:basic_metadata)
  include Hyrax::Indexer(:collection_resource)

  def to_solr
    super.tap do |index_document|
      # TODO: Do we need the indexing for bulkrax_identifier? If it is in the resource yml, it is probably redundant.
      solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      solr_doc['bulkrax_identifier_sim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      index_document["account_cname_tesim"] = Site.instance&.account&.cname
      index_document['account_institution_name_ssim'] = Site.instance.institution_label
    end
  end
end
