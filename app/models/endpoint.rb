class Endpoint < ApplicationRecord
  has_one :account

  def switchable_options
    options.select {|k,v| v.present? }
  end

end
