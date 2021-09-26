# frozen_string_literal: true

# @abstract
class NilEndpoint
  def ping
    false
  end

  def persisted?
    false
  end

  def remove!
    false
  end

  def assign_attributes(attr)
    false
  end
end
