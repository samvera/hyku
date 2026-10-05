# frozen_string_literal: true

# Helpers for the digital collection theme's search results page.
module DigitalCollectionSearchHelper
  def dc_results_summary(total, query)
    formatted = number_with_delimiter(total)
    return t('digital_collection.search.results.summary', count: total, formatted:) if query.blank?

    t('digital_collection.search.results.summary_query', count: total, formatted:, query:)
  end

  def dc_results_range(response)
    return if response.total.zero?

    first = response.start + 1
    t('digital_collection.search.results.range_html',
      first: number_with_delimiter(first),
      last: number_with_delimiter(response.start + response.documents.size),
      total: number_with_delimiter(response.total))
  end

  def dc_applied_filter_count
    search_state.filters.sum { |filter| Array(filter.values).flatten.compact_blank.size }
  end

  def dc_advanced_match_op
    return unless params[:search_field].present? && params[:search_field] == blacklight_config.advanced_search&.[](:url_key)

    keys = blacklight_config.search_fields.values.reject { |field| field.include_in_advanced_search == false }.map(&:key)
    return if keys.count { |key| params[key].present? } < 2

    params[:op] == 'OR' ? :any : :all
  end

  def dc_keyword_chips(search_state)
    query = advanced_query
    return if query.nil? || query.keyword_queries.empty?

    chips = query.keyword_queries.map do |field, value|
      remove = search_action_path(remove_advanced_keyword_query(field, search_state.params).except(:controller, :action))
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        render_constraint_element(blacklight_config.search_fields[field].display_label('search'), value, remove:)
      end
    end
    safe_join(chips, "\n")
  end

  def dc_filter_chips(search_state)
    core = Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
      Blacklight::RenderConstraintsHelperBehavior.instance_method(:render_constraints_filters).bind_call(self, search_state)
    end
    safe_join([core, dc_advanced_range_chips(search_state)].compact, "\n")
  end

  def dc_result_fields(document)
    fields = document.collection? ? dc_collection_result_values(document) : dc_work_result_values(document)
    fields.filter_map { |key, value| [key, t("digital_collection.search.results.fields.#{key}"), value] if value.present? }
  end

  private

  def dc_advanced_range_chips(search_state)
    return unless respond_to?(:advanced_query) && advanced_query

    chips = advanced_query.filters.filter_map do |field, values|
      next unless blacklight_config.facet_fields[field]&.range

      remove = search_action_path(remove_advanced_filter_group(field, search_state.params).except(:controller, :action))
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        render_constraint_element(facet_field_label(field), Array(values).join(', '), remove:)
      end
    end
    safe_join(chips, "\n") if chips.any?
  end

  def dc_work_result_values(document)
    { creator: Array(document['creator_tesim']).join('; '),
      date: Array(document['date_created_tesim']).first.presence || Array(document['date_issued_tesim']).first,
      part_of: dc_part_of_links(document),
      resource_type: Array(document['resource_type_tesim']).join(', '),
      description: theme_blurb(Array(document['description_tesim']).first, length: 300) }
  end

  def dc_collection_result_values(document)
    works = Hyrax::CollectionPresenter.new(document, current_ability).total_viewable_works
    { description: theme_blurb(Array(document['description_tesim']).first, length: 300),
      works: t('digital_collection.homepage.browse.works_count', count: works) }
  end

  def dc_part_of_links(document)
    ids = Array(document['member_of_collection_ids_ssim'])
    links = Array(document['member_of_collections_ssim']).each_with_index.map do |name, index|
      ids[index] ? link_to(name, hyrax.collection_path(ids[index])) : name
    end
    safe_join(links, ', ')
  end
end
