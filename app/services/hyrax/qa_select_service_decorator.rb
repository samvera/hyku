# OVERRIDE: Hyrax 3.4.2 fixes issues with empty authority and no implicit conversion of string into array

# frozen_string_literal: true

module Hyrax
  module QaSelectServiceDecorator
    
    def active?(id)
      result = authority.find(id)
      return false if result.empty?
      result&.fetch('active')
    end

    def include_current_value(value, _index, render_options, html_options)
      unless value.blank? || active?(value)
        html_options[:class] += [' force-select']
        render_options += [[label(value) { value }, value]]
      end
      [render_options, html_options]
    end
  end
end

Hyrax::QaSelectService.prepend(Hyrax::QaSelectServiceDecorator)
