# frozen_string_literal: true

class AppIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['account_cname_tesim'] = Site.instance&.account&.cname
      solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
      solr_doc['all_text_tsimv'] = full_text(object.file_sets.first&.id)
      add_date(solr_doc)
    end
  end

  def full_text(file_set_id)
    return if !Flipflop.default_pdf_viewer? || file_set_id.blank?

    SolrDocument.find(file_set_id)['all_text_tsimv']
  end

  def add_date(solr_doc)
    # The allowed date formats are either YYYY, YYYY-MM, or YYYY-MM-DD
    # the date must be formatted as a 4 digit year in order to be sorted.
    valid_date_formats = /\A(\d{4})(?:-\d{2}(?:-\d{2})?)?\z/
    date_string = solr_doc['date_created_tesim']&.first
    year = date_string&.match(valid_date_formats)&.captures&.first
    solr_doc['date_tesi'] = year if year
    solr_doc['date_ssi'] = year if year
  end
end
