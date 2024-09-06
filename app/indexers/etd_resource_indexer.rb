# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource EtdResource`
class EtdResourceIndexer < Hyrax::ValkyrieWorkIndexer
  # Commented out basic_metadata because these terms were added to etd_resource so we can customize it.
  # include Hyrax::Indexer(:basic_metadata)
  include Hyrax::Indexer(:bulkrax_metadata)
  include Hyrax::Indexer(:etd_resource)
  include Hyrax::Indexer(:with_pdf_viewer)
  include Hyrax::Indexer(:with_video_embed)

  include HykuIndexing

  # Uncomment this block if you want to add custom indexing behavior:
  #  def to_solr
  #    super.tap do |index_document|
  #      index_document[:my_field_tesim]   = resource.my_field.map(&:to_s)
  #      index_document[:other_field_ssim] = resource.other_field
  #    end
  #  end
end
