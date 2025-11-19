# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceIndexer < Hyrax::Indexers::PcdmCollectionIndexer
  if Hyrax.config.collection_include_metadata?
    include Hyrax::Indexer(:core_metadata)
    include Hyrax::Indexer(:basic_metadata)
    include Hyrax::Indexer(:bulkrax_metadata)
    include Hyrax::Indexer(:collection_resource)
  end
  check_if_flexible(CollectionResource)

  include Hyrax::IndexesThumbnails
  include HykuIndexing

  def to_solr
    super.tap do |index_document|
      index_document["account_cname_tesim"] = Site.instance&.account&.cname
      index_document['account_institution_name_ssim'] = Site.instance.institution_label
    end
  end
end
