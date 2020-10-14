# frozen_string_literal: true

# Provides a default host for the current tenant
class HykuMailer < ActionMailer::Base
  def default_url_options
    { host: host_for_tenant }
  end

  private

    def host_for_tenant
      Account.find_by(tenant: Apartment::Tenant.current)&.cname || Account.admin_host
    end
end
