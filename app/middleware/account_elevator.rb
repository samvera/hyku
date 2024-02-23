# frozen_string_literal: true

require 'apartment/elevators/generic'
# Apartment middleware for switching tenants based on the
# CNAME entry for an account.
class AccountElevator < Apartment::Elevators::Generic
  include AccountSwitch
  # @return [String] The tenant to switch to
  def parse_tenant_name(request)
    account = Account.from_request(request)
    account || Account.new.reset! # reset everything if no account is present
    account&.tenant
  end

  def self.switch!(cname)
    account = Account.from_cname(cname)
    if account
      Apartment::Tenant.switch!(account.tenant)
    elsif Account.any?
      raise "No tenant found for #{cname}"
    else
      Rails.logger.info "It looks like we're in single tenant mode. No tenant found for #{cname}"
    end
  end
end
