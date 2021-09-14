# frozen_string_literal: true

# Copied from Hyrax v2.9.0 to update FEATURE_LIMIT to 6
class FeaturedWork < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
  FEATURE_LIMIT = 6
  validate :count_within_limit, on: :create
  validates :order, inclusion: { in: proc { 0..FEATURE_LIMIT } }

  default_scope { order(:order) }

  def count_within_limit
    return if FeaturedWork.can_create_another?
    errors.add(:base, "Limited to #{FEATURE_LIMIT} featured works.")
  end

  attr_accessor :presenter

  class << self
    def can_create_another?
      FeaturedWork.count < FEATURE_LIMIT
    end
  end
end
