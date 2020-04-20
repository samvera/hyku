module HykuHelper
  def multitenant?
    Settings.multitenancy.enabled
  end

  def current_account
    @current_account ||= Account.from_request(request)
    @current_account ||= Account.single_tenant_default
  end

  def admin_host?
    return false unless multitenant?

    Account.canonical_cname(request.host) == Account.admin_host
  end
end
