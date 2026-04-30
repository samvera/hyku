# frozen_string_literal: true

# OVERRIDE Flipflop v2.7.1 to allow for custom `Action` labels

module Flipflop
  module StrategiesControllerDecorator
    def self.prepended(base)
      base.before_action :ensure_clover_viewer_feature_exists
    end

    def ensure_clover_viewer_feature_exists
      # Ensure clover_viewer feature exists in the database for this tenant
      unless Flipflop::Feature.exists?(key: 'clover_viewer')
        Flipflop::Feature.create!(key: 'clover_viewer', enabled: false)
      end
    end

    def enable?
      values = StrategiesController::ENABLE_VALUES | ADDITIONAL_ENABLE_VALUES
      values.include?(params[:commit])
    end

    ADDITIONAL_ENABLE_VALUES = FeaturesHelper::FEATURE_ACTION_LABELS.map { |_, v| v[:on] }.to_set.freeze
  end
end

Flipflop::StrategiesController.prepend(Flipflop::StrategiesControllerDecorator)
