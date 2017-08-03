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
end
