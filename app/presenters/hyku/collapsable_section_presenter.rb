# frozen_string_literal: true

module Hyku
  # Draws a collapsable list widget using the Bootstrap 3 / Collapse.js plugin
  class CollapsableSectionPresenter < Hyrax::CollapsableSectionPresenter
    # Override Hyrax 3.5.0 to pass in html_options
    # rubocop:disable Metrics/ParameterLists
    def initialize(view_context:, text:, id:, icon_class:, open:, html_options: {})
      # rubocop:enable Metrics/ParameterLists
      super(view_context:, text:, id:, icon_class:, open:)
      @html_options = html_options
    end

    attr_reader :html_options

    private

    def button_tag
      tag.a({ role: 'button',
              class: "#{button_class}collapse-toggle",
              data: { toggle: 'collapse' },
              href: "##{id}",
              onclick: "toggleCollapse(this)",
              'aria-expanded' => open,
              'aria-controls' => id }.merge(html_options)) do
        safe_join([tag.span('', class: icon_class, 'aria-hidden': true),
                   tag.span(text)], ' ')
      end
    end
  end
end
