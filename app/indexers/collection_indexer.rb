# frozen_string_literal: true

class CollectionIndexer < Hyrax::CollectionIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      solr_doc['bulkrax_identifier_sim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      solr_doc["account_cname_tesim"] = Site.instance&.account&.cname
      solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
    end
  end
end
