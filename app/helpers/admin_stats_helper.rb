# frozen_string_literal: true

module AdminStatsHelper
  def graph_tag(id, data, options)
    content_tag :div, class: 'graph-container',
                      data: { graph_data: data.to_json,
                              graph_options: options } do
      content_tag :div, nil, class: 'graph', id:
    end
  end

  # A year of 30-day steps ending today, so a quiet month still shows the repository's
  # growth and the last point counts today's deposits
  def over_time
    x_max = Time.zone.now.end_of_day
    { delta_x: 30, x_min: x_max - 360.days, x_max: }
  end

  # Hyrax's Collections chart steps before it counts, so its window sits a step earlier to end on today
  def collections_over_time
    window = over_time
    window.merge(x_min: window[:x_min] - 30.days, x_max: window[:x_max] - 30.days)
  end
end
