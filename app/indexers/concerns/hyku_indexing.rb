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
        solr_doc[CatalogController.created_field] ||= Array(object.try(:date_created)).first
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
    members = Hyrax.custom_queries.find_child_file_sets(resource: object).to_a

    return [] if members.empty?

    text_file_sets = members.select { |fs| fs.file_set? && fs.original_file&.mime_type == 'text/plain' }
    text_file_sets.map { |fs| scrub_text(fs.original_file&.content) }
  end

  # Aggregate each child work's already-indexed full text from Solr rather than
  # re-deriving every child work's file-set text from disk on each reindex.
  #
  # A parent work is reindexed several times per save (the WorkUpdate
  # transaction publishes `object.metadata.updated` and
  # `object.membership.updated`, plus the ACL reindex), and the old path walked
  # Postgres for each child work, queried each child's file sets, and read each
  # derivative from disk every time. That is O(child works x file sets) per
  # reindex and made saving a "hub" work with many children time out (a
  # ~95-child work took 60-70s, past common ingress timeouts).
  #
  # Every child work is indexed by this same concern, so its `all_text_tsimv`
  # already holds its (and its descendants') text. One batched Solr read keyed
  # on `member_ids` recovers the same content in a single round trip regardless
  # of child/file-set count. A child not yet indexed contributes on the next
  # reindex (eventual consistency), which matches how derived text already
  # propagates.
  def extract_text_from_child_works(object)
    member_ids = Array(object.member_ids).map(&:to_s).reject(&:blank?)
    return extract_text_from_pdf_directly(object) if member_ids.empty?

    texts = child_work_full_texts(member_ids)
    return extract_text_from_pdf_directly(object) if texts.blank?

    texts.join("\n---------------------------\n")
  end

  # The members' already-indexed full text, in one query. `fq` on generic_type
  # keeps file-set members out; the parent's own file sets are handled by
  # `extract_text_from_plain_text_files`.
  def child_work_full_texts(member_ids)
    Hyrax::SolrService.query(
      "{!terms f=id}#{member_ids.join(',')}",
      fq: 'generic_type_sim:Work',
      fl: 'all_text_tsimv',
      rows: member_ids.length
    ).flat_map { |doc| Array(doc['all_text_tsimv']) }.select(&:present?)
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
