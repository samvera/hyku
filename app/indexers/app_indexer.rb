# frozen_string_literal: true

class AppIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for based_near. You can remove this if you don't want
  # this behavior
  include Hyrax::IndexesLinkedMetadata

  include HykuIndexing

  # TODO: Extract to HykuIndexing?

  # Uncomment this block if you want to add custom indexing behavior:
  # rubocop:disable Metrics/AbcSize
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc['title_ssi'] = SortTitle.new(object.title.first).alphabetical
      solr_doc['depositor_ssi'] = object.depositor
      solr_doc['creator_ssi'] = object.creator&.first
      solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
      solr_doc['account_cname_tesim'] = Site.instance&.account&.cname
      solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
      solr_doc['all_text_tsimv'] = full_text(object.file_sets.first&.id)
      add_date(solr_doc)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def full_text(file_set_id)
    return if !Flipflop.default_pdf_viewer? || file_set_id.blank?

    SolrDocument.find(file_set_id)['all_text_tsimv']
  end

  def add_date(solr_doc)
    date_string = solr_doc['date_created_tesim']&.first
    return unless date_string

    date_string = pad_date_with_zero(date_string) if date_string.include?('-')

    # The allowed date formats are either YYYY, YYYY-MM, or YYYY-MM-DD
    valid_date_formats = /\A(\d{4}(?:-\d{2}(?:-\d{2})?)?)\z/
    date = date_string&.match(valid_date_formats)&.captures&.first

    # If the date is not in the correct format, index the original date string
    date ||= date_string

    solr_doc['date_tesi'] = date if date
    solr_doc['date_ssi'] = date if date
  end

  def pad_date_with_zero(date_string)
    date_string.split('-').map { |d| d.rjust(2, '0') }.join('-')
  end
end
