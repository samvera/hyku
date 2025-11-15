# frozen_string_literal: true

module FeaturedWorkDecorator
  extend ActiveSupport::Concern

  class_methods do
    def feature_limit
      6
    end
  end
end

FeaturedWork.prepend(FeaturedWorkDecorator)
