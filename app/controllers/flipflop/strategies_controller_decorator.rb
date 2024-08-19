# frozen_string_literal: true

# OVERRIDE Flipflop v2.7.1 to allow for custom `Action` labels

module Flipflop
  module StrategiesControllerDecorator
    def enable?
      values = StrategiesController::ENABLE_VALUES | ADDITIONAL_ENABLE_VALUES
      values.include?(params[:commit])
    end

    ADDITIONAL_ENABLE_VALUES = FeaturesHelper::FEATURE_ACTION_LABELS.map { |_, v| v[:on] }.to_set.freeze
  end
end

Flipflop::StrategiesController.prepend(Flipflop::StrategiesControllerDecorator)
