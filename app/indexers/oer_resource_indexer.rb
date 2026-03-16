# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource OerResource`
class OerResourceIndexer < Hyrax::ValkyrieWorkIndexer
  if Hyrax.config.work_include_metadata?
    include Hyrax::Indexer(:core_metadata)
    # Commented out basic_metadata because the terms were added to the resource's yaml
    # so we can customize it
    # include Hyrax::Indexer(:basic_metadata)
    include Hyrax::Indexer(:bulkrax_metadata)
    include Hyrax::Indexer(:oer_resource)
    include Hyrax::Indexer(:with_pdf_viewer)
    include Hyrax::Indexer(:with_video_embed)
  end
  check_if_flexible(OerResource)

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
