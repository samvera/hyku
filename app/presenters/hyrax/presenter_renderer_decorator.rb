# frozen_string_literal: true

# OVERRIDE Hyrax 5.2.0 to display based near label instead of URI
# @TODO Move this behavior into Hyrax in a flexible manner
module Hyrax
  module PresenterRendererDecorator
    def value(field_name, locals = {})
      field_name == :based_near ? super(:based_near_label, locals) : super(field_name, locals)
    end
  end
end

Hyrax::PresenterRenderer.prepend(Hyrax::PresenterRendererDecorator)
