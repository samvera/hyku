# frozen_string_literal: true

class Endpoint < ApplicationRecord
  has_one :account

  def switchable_options
    options.select { |_k, v| v.present? }
  end
end
