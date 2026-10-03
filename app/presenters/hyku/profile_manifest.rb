# frozen_string_literal: true

module Hyku
  ##
  # For a flexible work, a child work's canvases carry that child's metadata, and
  # the work's own canvases carry none, since the manifest already shows it. With
  # file_set_metadata on, each canvas also carries its file set's metadata.
  module ProfileManifest
    attr_accessor :file_set_metadata, :pages_set_by_parent

    # Hyku::Ranges copies each work's metadata onto its own pages. When the
    # top-level work sets every page itself, its child works skip that copy.
    def member_presenters
      super.each { |member| member.try(:pages_set_by_parent=, sets_pages?) }
    end

    # Whether this manifest's pages carry their file sets' own metadata.
    def file_set_pages?
      file_set_metadata.present? && profiled?
    end

    # Pages also carry metadata from child works and file sets, and labels in the
    # current locale, so the cached manifest's version changes with any of them.
    def version(**kwargs)
      return super if kwargs.key?(:seen) || !profiled?

      # `_version_` changes on every index write, so a reindex that only changes
      # labels or the profile version also changes the stamp.
      stamps = descendant_documents.map { |document| "#{document.id}:#{document['_version_'] || document['system_modified_dtsi']}" }.sort
      "#{super}|#{I18n.locale}|pages:#{Digest::MD5.hexdigest(stamps.join(','))}"
    end

    def item_metadata
      return if pages_set_by_parent
      return super unless profiled?

      super if public?(model.solr_document)
    end

    # Hyku::Ranges recurses into child works with seen:, and the top-level call
    # sets every page, so the nested calls leave theirs alone.
    def file_set_presenters(**kwargs)
      presenters = super
      return presenters if kwargs.key?(:seen) || !profiled?

      metadata = page_metadata_by_file_set(presenters)
      presenters.each { |presenter| presenter.item_metadata = metadata[presenter.id.to_s] }
    end

    private

    def profiled?
      Hyku::ProfileManifestMetadata.applies_to?(model.solr_document)
    end

    def sets_pages?
      pages_set_by_parent.nil? ? profiled? : pages_set_by_parent
    end

    def page_metadata_by_file_set(presenters)
      @page_metadata_by_file_set ||= begin
        owners = child_work_owners(presenters.map { |p| p.id.to_s })
        presenters.to_h { |presenter| [presenter.id.to_s, page_metadata(presenter, owners[presenter.id.to_s])] }
      end
    end

    def page_metadata(presenter, child_owner)
      return child_owner && owner_metadata(child_owner) unless file_set_metadata

      file_set = public?(presenter.model) ? Hyku::ProfileManifestMetadata.for_file_set(presenter.model, base_url:, definitions:) : []
      child_owner ? owner_metadata(child_owner) + file_set : file_set
    end

    def child_work_owners(file_set_ids)
      descendant_documents.reject(&:file_set?).each_with_object({}) do |owner, map|
        (owner.member_ids & file_set_ids).each { |fs_id| map[fs_id] ||= owner }
      end
    end

    # This work's descendants, found one level of members at a time rather than
    # from the indexed descendant list, which goes stale when a grandchild joins
    # later. Only this tree is searched, since a file set can also be a member of
    # an unrelated work.
    def descendant_documents
      @descendant_documents ||= begin
        seen = Set[id.to_s]
        documents = []
        level = Array(model.solr_document.member_ids).map(&:to_s)
        until level.empty?
          found = Hyrax::SolrService.query("{!terms f=id}#{level.join(',')}", rows: level.size).map { |hit| ::SolrDocument.new(hit) }
          found.select! { |document| seen.add?(document.id.to_s) }
          documents.concat(found)
          level = found.reject(&:file_set?).flat_map(&:member_ids).map(&:to_s) - seen.to_a
        end
        documents
      end
    end

    def owner_metadata(owner)
      @owner_metadata ||= {}
      @owner_metadata[owner.id] ||=
        if !public?(owner)
          []
        elsif Hyku::ProfileManifestMetadata.applies_to?(owner)
          Hyku::ProfileManifestMetadata.for_work(owner, base_url:, definitions:)
        else
          Hyku::IiifMetadataHtml.sanitize_entries(
            IiifPrint.manifest_metadata_for(work: owner, current_ability: anonymous_ability, base_url:), base_url:
          )
        end
    end

    def definitions
      @definitions ||= {}
    end

    # The manifest is cached publicly, so pages carry only what an anonymous
    # visitor may read, whoever requested it.
    def public?(document)
      anonymous_ability.can?(:read, document)
    end

    def anonymous_ability
      @anonymous_ability ||= ::Ability.new(nil)
    end
  end
end
