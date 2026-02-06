# frozen_string_literal: true

##
# A mixin for all additional Hyku applicable indexing; both Valkyrie and ActiveFedora friendly.
module HykuIndexing
  include ScrubText
  # TODO: Once we've fully moved to Valkyrie, remove the generate_solr_document and move `#to_solr`
  #      to a more conventional method def (e.g. `def to_solr`).  However, we need to tap into two
  #      different inheritance paths based on ActiveFedora or Valkyrie
  [:generate_solr_document, :to_solr].each do |method_name|
    define_method method_name do |*args, **kwargs, &block|
      super(*args, **kwargs, &block).tap do |solr_doc|
        # rubocop:disable Style/ClassCheck

        # Active Fedora refers to object
        # Specs refer to object as @object
        # Valkyrie refers to resource
        object ||= @object || resource
        solr_doc['generic_type_sim'] = ['Work'] if object.is_a?(Hyrax::Work)
        solr_doc['account_cname_tesim'] = Site.instance&.account&.cname
        solr_doc['bulkrax_identifier_tesim'] = object.bulkrax_identifier if object.respond_to?(:bulkrax_identifier)
        solr_doc['account_institution_name_ssim'] = Site.instance.institution_label
        solr_doc['valkyrie_bsi'] = object.kind_of?(Valkyrie::Resource)
        solr_doc['member_ids_ssim'] = object.member_ids.map(&:to_s)
        solr_doc['all_text_tsimv'] = extract_full_text(object)
        # rubocop:enable Style/ClassCheck
        solr_doc['title_ssi'] = SortTitle.new(object.title.first).alphabetical
        solr_doc['depositor_ssi'] = object.depositor
        solr_doc['creator_ssi'] = object.creator&.first
        if object.respond_to?(:date_created)
          solr_doc[CatalogController.created_field] =
            Array(object.date_created).first
        end
        add_date(solr_doc)
      end
    end
  end

  private

  # @TODO: This method only supports Valkyrie, and does not support ActiveFedora, even
  #        though it is used in the ActiveFedora indexer.
  def extract_full_text(object)
    texts = []

    texts << extract_text_from_plain_text_files(object)
    texts << extract_text_from_child_works(object)

    texts.flatten.compact.join(' ').strip
  end

  def extract_text_from_plain_text_files(object)
    members = Hyrax.custom_queries.find_child_file_sets(resource: object)

    return [] if members.blank?

    text_file_sets = members.select { |fs| fs.file_set? && fs.original_file&.mime_type == 'text/plain' }
    text_file_sets.map { |fs| scrub_text(fs.original_file&.content) }
  end

  def extract_text_from_child_works(object)
    child_works = Hyrax.custom_queries.find_child_works(resource: object)

    return extract_text_from_pdf_directly(object) if child_works.empty?

    file_set_texts = child_works_file_sets(child_works).map { |fs| all_text(fs) }.select(&:present?)

    return extract_text_from_pdf_directly(object) if file_set_texts.join.blank?

    file_set_texts.join("\n---------------------------\n")
  end

  def extract_text_from_pdf_directly(object)
    file_set = Hyrax.custom_queries.find_child_file_sets(resource: object).first
    file_set_id = file_set&.id&.to_s
    return if file_set_id.blank?

    SolrDocument.find(file_set_id)['all_text_tsimv']
  rescue Blacklight::Exceptions::RecordNotFound
    file_set_doc = Hyrax::Indexers::ResourceIndexer.for(resource: file_set).to_solr
    return file_set_doc&.[]('all_text_tsimv')
  end

  def child_works_file_sets(child_works)
    child_works.map { |child_work| Hyrax.custom_queries.find_child_file_sets(resource: child_work) }.flatten
  end

  def all_text(fs)
    text = IiifPrint::Data::WorkDerivatives.data(from: fs, of_type: 'txt') || ''
    return text if text.empty?

    text.tr("\n", ' ').squeeze(' ')
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
