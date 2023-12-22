# frozen_string_literal: true

module Hyku
  # Draws a collapsable list widget using the Bootstrap 4 / Collapse.js plugin
  class CollapsableSectionPresenter < Hyrax::CollapsableSectionPresenter
    # Override Hyrax v5.0.0rc2 to pass in the title attribute
    # rubocop:disable Metrics/ParameterLists
    def initialize(view_context:, text:, id:, icon_class:, open:, title: nil)
      # rubocop:enable Metrics/ParameterLists
      super(view_context:, text:, id:, icon_class:, open:)
      @title = title
    end

    attr_reader :title

    private

    def button_tag
      tag.a(role: 'button',
            class: "#{button_class}collapse-toggle nav-link",
            data: { toggle: 'collapse' },
            href: "##{id}",
            onclick: "toggleCollapse(this)",
            'aria-expanded' => open,
            'aria-controls' => id,
            title:) do
        safe_join([tag.span('', class: icon_class, 'aria-hidden': true),
                   tag.span(text)], ' ')
      end
    end
  end
end
