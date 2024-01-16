# frozen_string_literal: true

##
# Similar to Hyrax's {FeaturedWork} model.
class FeaturedCollection < ApplicationRecord
  ##
  # @!group Class Attributes
  #
  # @!attribute feature_limit [r/w]
  #   @return [Integer] The maximum number of collections to feature.
  class_attribute :feature_limit, default: 6
  # @!endgroup Class Attributes
  ##

  validate :count_within_limit, on: :create
  validates :order, inclusion: { in: proc { 0..feature_limit } }

  default_scope { order(:order) }

  def self.destroy_for(collection:)
    where(collection_id: collection.id).destroy_all
  end

  def count_within_limit
    return if FeaturedCollection.can_create_another?
    errors.add(:base, "Limited to #{feature_limit} featured collections.")
  end

  attr_accessor :presenter

  def self.can_create_another?
    FeaturedCollection.count < feature_limit
  end
end
