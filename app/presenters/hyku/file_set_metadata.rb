# frozen_string_literal: true

module Hyku
  ##
  # Lets a work type's IIIF manifest give each page its own file set's metadata.  A works controller opts in
  # with `self.iiif_file_set_metadata = true`.  A page that belongs to a child work keeps that child's
  # metadata, which Hyku::Ranges puts there, and the file set's follows it.
  #
  # A page carries its file set's metadata as IiifPrint.manifest_metadata_from builds it from the file set's
  # metadata profile, even when the file set is restricted: Hyrax leaves restricted pages out of an anonymous
  # visitor's manifest, and Hyku does not let any other manifest be shared.  A file set without a profile, or
  # an IiifPrint too old to read one, adds nothing, since IiifPrint's configured fields are work fields.
  module FileSetMetadata
    attr_accessor :iiif_file_set_metadata

    def file_set_presenters(seen: Set.new)
      presenters = super(seen: seen)
      return presenters unless iiif_file_set_metadata

      presenters.each { |presenter| presenter.item_metadata = page_metadata(presenter) }
    end

    # A page's metadata now depends on its file set, so the manifest's version follows the newest change to
    # any member, or with IIIF ranges on any child work's member, which Solr finds in one row however many
    # pages the work has.
    def version(seen: Set.new)
      return super(seen: seen) unless iiif_file_set_metadata

      ['file_sets', super(seen: seen), newest_member_change].join('|')
    end

    private

    # Hyrax asks for the pages several times while building one manifest, so each page's metadata is put
    # together once, from what the page carried the first time.
    def page_metadata(presenter)
      @page_metadata ||= {}
      @page_metadata[presenter.id.to_s] ||= Array(presenter.item_metadata) + file_set_metadata(presenter.model)
    end

    def newest_member_change
      return @newest_member_change if defined?(@newest_member_change)

      ids = page_member_ids
      return @newest_member_change = nil if ids.empty?

      @newest_member_change = Hyrax::SolrService.query("{!terms f=id}#{ids.join(',')}",
                                                       fl: 'system_modified_dtsi', sort: 'system_modified_dtsi desc', rows: 1, method: :post)
                                                .first&.fetch('system_modified_dtsi', nil)
    end

    def page_member_ids(seen = Set.new)
      return [] unless seen.add?(id.to_s)
      return member_ids unless Flipflop.iiif_ranges?

      member_ids + child_work_presenters.flat_map { |child| child.send(:page_member_ids, seen) }
    end

    def file_set_metadata(document)
      return [] unless defined?(IiifPrint::Flexibility) && IiifPrint::Flexibility.applies_to?(document)

      IiifPrint.manifest_metadata_from(work: document, presenter: self)
    end
  end
end
