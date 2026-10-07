# frozen_string_literal: true

# Helpers for the digital collection theme's work page.
module DigitalCollectionWorkHelper
  DC_WORK_SHOWN_ELSEWHERE = '.attribute-title, .attribute-description'

  def dc_work_metadata_rows(presenter)
    fragment = Nokogiri::HTML::DocumentFragment.parse(dc_external_links_in_new_tab(render('hyrax/base/attribute_rows', presenter:)))
    fragment.css('dt').filter_map do |term|
      values = dc_row_values(term)
      next if values.any? { |value| value.at_css(DC_WORK_SHOWN_ELSEWHERE) }

      safe_join([term, *values].map { |node| node.to_html.html_safe }) # rubocop:disable Rails/OutputSafety
    end
  end

  def dc_work_collections(work)
    @dc_work_collections ||= {}
    @dc_work_collections[work.id] ||= work.member_of_collection_presenters.to_a
  end

  def dc_part_of_groups(presenter)
    collections = dc_work_collections(presenter).map { |collection| [collection.to_s, search_state.url_for_document(collection)] }
    parents = presenter.parent_works(current_user).map { |parent| [parent.title.first, parent_path(parent)] }
    admin_sets = presenter.editor? ? Array(presenter.admin_set).map { |name| [name, main_app.search_catalog_path(f: { admin_set_sim: [name] })] } : []
    { collection: collections, parent_work: parents, admin_set: admin_sets }.filter_map do |kind, links|
      [t("digital_collection.work.part_of.#{kind}", count: links.size), links] if links.any?
    end
  end

  private

  def dc_row_values(term)
    values = []
    node = term.next_element
    while node&.name == 'dd'
      values << node
      node = node.next_element
    end
    values
  end
end
