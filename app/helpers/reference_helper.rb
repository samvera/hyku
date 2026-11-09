# frozen_string_literal: true

# Helpers for the reference theme's home and show pages.
module ReferenceHelper
  def ref_home
    theme_home(Reference::HomepagePresenter)
  end

  def ref_creators(object, limit: 3)
    names = Array(object.creator).reject(&:blank?)
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

  def ref_show_panes(presenter)
    @ref_show_panes ||= [].tap do |panes|
      panes << [:metadata, t('reference.show.tabs.metadata'), nil]

      files = theme_file_set_ids(presenter)
      children = theme_child_work_ids(presenter)
      panes << [:files, t('reference.show.tabs.files'), files.total_count] if files.any?
      panes << [:children, t('reference.show.tabs.children'), children.total_count] if children.any?
    end
  end
end
