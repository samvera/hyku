# @abstract
class NilEndpoint
  def ping
    false
  end

  def persisted?
    false
  end
end
