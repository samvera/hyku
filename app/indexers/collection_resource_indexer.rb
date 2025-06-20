# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:collection_resource CollectionResource`
class CollectionResourceIndexer < Hyrax::Indexers::PcdmCollectionIndexer
  include Hyrax::Indexer(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:collection_resource) unless Hyrax.config.flexible?
  include Hyrax::Indexer('CollectionResource') if Hyrax.config.flexible?

  include Hyrax::IndexesThumbnails
  include HykuIndexing

  def to_solr
    super.tap do |index_document|
      index_document["account_cname_tesim"] = Site.instance&.account&.cname
      index_document['account_institution_name_ssim'] = Site.instance.institution_label
    end
  end
end
