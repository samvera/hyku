# frozen_string_literal: true

# Helpers for the reference theme's home page.
module ReferenceHomeHelper
  def ref_home
    @ref_home ||= Reference::HomepagePresenter.new(
      search_service: controller.search_service,
      response: @response,
      collections: @collections,
      featured_work_list: @featured_work_list,
      featured_collection_list: @featured_collection_list,
      current_ability:
    )
  end

  def ref_creators(document, limit: 3)
    names = Array(document.creator).reject(&:blank?)
    return if names.empty?

    shown = names.first(limit).join('; ')
    names.size > limit ? "#{shown}; #{t('reference.homepage.recent.and_others')}" : shown
  end

  def ref_provenance(document)
    parts = [Array(document.publisher).first,
             Array(document.date_created).first,
             Array(document['member_of_collections_ssim']).first].compact_blank
    parts << t('reference.homepage.recent.embargo') if document.embargo_release_date.present?
    parts.join(' · ').presence
  end

  def ref_rights_statement(document)
    uri = Array(document.rights_statement).first
    return if uri.blank?

    (@ref_rights_service ||= Hyrax::RightsStatementService.new).label(uri)
  end
end
