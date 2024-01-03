# frozen_string_literal: true

module AdminStatsHelper
  def graph_tag(id, data, options)
    content_tag :div, class: 'graph-container',
                      data: { graph_data: data.to_json,
                              graph_options: options } do
      content_tag :div, nil, class: 'graph', id:
    end
  end
end
