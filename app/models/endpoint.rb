# frozen_string_literal: true

class Endpoint < ApplicationRecord
  has_one :account

  # if an option is blank on an endpoint, the whole app process will crash
  # when going to that tenant as fedora_url becomes blank. This code
  # prevents that and other nastiness in the event of added or removed
  # options or when data gets converted from one format to another between
  # JSON and a Ruby hash
  def switchable_options
    options.select { |_k, v| v.present? }
  end
end
