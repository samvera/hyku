# frozen_string_literal: true

# OVERRIDE Blacklight 6.7.0 to enable markdown for the facet constraints

require_dependency Blacklight::Engine.root.join('app', 'helpers', 'blacklight', 'render_constraints_helper_behavior').to_s

Blacklight::RenderConstraintsHelperBehavior.class_eval do
  # OVERRIDE to enable markdown in the facet constraints
  def render_constraint_element(label, value, options = {})
    render(partial: "catalog/constraints_element", locals: { label: label, value: markdown(value), options: options })
  end
end
