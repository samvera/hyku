# frozen_string_literal: true

module Hyrax
  # Builds the read-only list of file sets already attached to a work, for
  # display on the form's Files tab.
  module AttachedFilesHelperBehavior
    # @param form [Hyrax::Forms::PcdmObjectForm] the work form being rendered
    # @return [Array<Hyrax::FileSetPresenter>] presenters for the work's
    #   attached file sets, in the work's member order
    def attached_file_set_presenters(form)
      member_ids = Array(form.try(:member_ids)).map(&:to_s).reject(&:blank?)
      return [] if member_ids.blank?

      documents = Hyrax::SolrQueryService.new
                                         .with_ids(ids: member_ids)
                                         .solr_documents(rows: member_ids.size)
                                         .select(&:file_set?)

      # Solr does not honor the order of an id list, so restore member order.
      documents
        .sort_by { |document| member_ids.index(document.id) || member_ids.size }
        .map { |document| Hyrax::FileSetPresenter.new(document, current_ability, request) }
    end
  end
end
