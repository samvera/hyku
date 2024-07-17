# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource OerResource`
class OerResourceIndexer < Hyrax::ValkyrieWorkIndexer
  include Hyrax::Indexer(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:oer_resource) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:with_pdf_viewer) unless Hyrax.config.flexible?
  include Hyrax::Indexer(:with_video_embed) unless Hyrax.config.flexible?
  include Hyrax::Indexer('OerResource') if Hyrax.config.flexible?

  include HykuIndexing

  # Uncomment this block if you want to add custom indexing behavior:
  def to_solr
    super.tap do |index_document|
      index_document[:previous_version_id_tesim] = index_document[:previous_version_id_sim] = resource.previous_version_id.map(&:to_s)
      index_document[:newer_version_id_tesim] = index_document[:newer_version_id_sim] = resource.newer_version_id.map(&:to_s)
      index_document[:alternate_version_id_tesim] = index_document[:alternate_version_id_sim] = resource.alternate_version_id.map(&:to_s)
      index_document[:related_item_id_tesim] = index_document[:related_item_id_sim] = resource.related_item_id.map(&:to_s)
    end
  end
end
