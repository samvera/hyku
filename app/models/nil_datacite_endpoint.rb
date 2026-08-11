# frozen_string_literal: true

# Stands in for a tenant with no DataCite account. NilEndpoint supplies switch!, ping, and
# the rest; these readers exist because the proprietor account form reads them to render
# empty fields.
class NilDataCiteEndpoint < NilEndpoint
  def mode
    nil
  end

  def prefix
    nil
  end

  def username
    nil
  end

  def password
    nil
  end
end
