# have to override some methods from BlacklightAdvancedSearch classes/modules
# to provide date range search functionality
require BlacklightAdvancedSearch::Engine.root.join(Rails.root, 'config', 'initializers',
  'patch_blacklight_advanced_search')

class BlacklightAdvancedSearch::QueryParser
  # override to add date range to query
  def process_query(params, config)
    queries = keyword_queries.map do |field, query|
      ParsingNesting::Tree.parse(query,
        config.advanced_search[:query_parser]).to_query(local_param_hash(field,
          config))
    end
    queries.join(" #{keyword_op} ")
    return queries if params[:date_start].blank? && params[:date_end].blank?
    if queries.blank?
      add_date_range_to_queries(params)
    else
      [queries, add_date_range_to_queries(params)].join(' AND ')
    end
  end

  # format date input for Solr
  def add_date_range_to_queries(params)
    range_start = if params[:date_start].blank? || params[:date_start].match(/[\D]+/)
                    '*'
                  else
                    params[:date_start] + '-01-01T00:00:00.000Z'
                  end
    range_end = if params[:date_end].blank? || params[:date_end].match(/[\D]+/)
                  '*'
                else
                  params[:date_end] + '-12-31T23:59:59.999Z'
                end
    '(publication_date_dtsi:[' + range_start + ' TO ' + range_end + '])'
  end
end

module BlacklightAdvancedSearch::RenderConstraintsOverride
  # override to add date range to constraints rendering
  def render_constraints_filters(my_params = params)
    # these lines are copied from source
    content = super(my_params)
    if advanced_query
      advanced_query.filters.each_pair do |field, value_list|
        label = facet_field_label(field)
        content << render_constraint_element(label,
          safe_join(Array(value_list), " <strong class='text-muted constraint-connector'>OR</strong> ".html_safe),
          remove: search_action_path(remove_advanced_filter_group(field, my_params).except(:controller, :action)))
      end
      # this is our new line
      content << render_advanced_date_query(my_params)
    end
    content
  end

  # render the advanced search date query constraints
  def render_advanced_date_query(localized_params = params)
    return ''.html_safe if localized_params[:date_start].blank? && localized_params[:date_end].blank?
    render_constraint_element(t('blacklight.advanced_search.constraints.date'),
      date_range_constraints_to_s(localized_params),
      classes: ['date_range'],
      remove: remove_constraint_url(localized_params.merge(date_start: nil,
                                                           date_end: nil,
                                                           action: 'index')))
  end

  # render date range constraint text from Advanced Search form
  def date_range_constraints_to_s(params)
    return "#{params[:date_end]} or before" if params[:date_start].blank?
    return "#{params[:date_start]} or later" if params[:date_end].blank?
    "#{params[:date_start]}-#{params[:date_end]}"
  end
end
