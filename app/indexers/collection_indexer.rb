# frozen_string_literal: true

class CollectionIndexer < Hyrax::CollectionIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      solr_doc['title_ssi'] = SortTitle.new(object.title.first).alphabetical
      solr_doc['depositor_ssi'] = object.depositor
      solr_doc['creator_ssi'] = object.creator&.first
      solr_doc["account_cname_tesim"] = Site.instance&.account&.cname
      solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
    end
  end
end
