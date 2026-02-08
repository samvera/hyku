# frozen_string_literal: true

# @abstract
class NilEndpoint
  def self.reset!
    false
  end

  def ping
    false
  end

  def persisted?
    false
  end

  def remove!
    false
  end

  def assign_attributes(_attr)
    false
  end

  def switch!
    false
  end

  def marked_for_destruction?
    false
  end
end
