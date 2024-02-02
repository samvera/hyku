# frozen_string_literal: true

##
# A mixin for all additional Hyku applicable indexing; both Valkyrie and ActiveFedora friendly.
module HykuIndexing
  # TODO: Once we've fully moved to Valkyrie, remove the generate_solr_document and move `#to_solr`
  #      to a more conventional method def (e.g. `def to_solr`).  However, we need to tap into two
  #      different inheritance paths based on ActiveFedora or Valkyrie
  [:generate_solr_document, :to_solr].each do |method_name|
    define_method method_name do |*args, **kwargs, &block|
      super(*args, **kwargs, &block).tap do |solr_doc|
        # rubocop:disable Style/ClassCheck

        # specs refer to object as @object
        object ||= @object || resource

        solr_doc['account_cname_tesim'] = Site.instance&.account&.cname
        solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
        solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
        solr_doc['valkyrie_bsi'] = object.kind_of?(Valkyrie::Resource)
        solr_doc['member_ids_ssim'] = object.member_ids.map(&:id)
        # TODO: Reinstate once valkyrie fileset work is complete - https://github.com/scientist-softserv/hykuup_knapsack/issues/34
        solr_doc['all_text_tsimv'] = full_text(object.file_sets.first&.id) if object.kind_of?(ActiveFedora::Base)
        # rubocop:enable Style/ClassCheck
        add_date(solr_doc)
      end
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
