# frozen_string_literal: true

module FeaturesHelper
  def status_for(feature)
    status = @feature_set.status(feature)
    label = @feature_set.status(feature) == :enabled ? :on : :off
    FEATURE_ACTION_LABELS.fetch(feature.name.to_sym, label => status)[label]
  end

  def on(feature)
    FEATURE_ACTION_LABELS[feature]&.[](:on) || 'on'
  end

  def off(feature)
    FEATURE_ACTION_LABELS[feature]&.[](:off) || 'off'
  end

  FEATURE_ACTION_LABELS = {
    default_pdf_viewer: { on: 'PDF.js', off: 'UV' }
  }.freeze
end
