# frozen_string_literal: true

class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory
  helper BlacklightAdvancedSearch::RenderConstraintsOverride
  helper RangeLimitHelper
end
