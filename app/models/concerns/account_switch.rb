# frozen_string_literal: true

module AccountSwitch
  extend ActiveSupport::Concern

  DOMAIN_REGEXP = %r{^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,8}(:[0-9]{1,5})?(/.*)?$}ix

  class_methods do
    def switch!(cname_or_name_or_account)
      account = if cname_or_name_or_account.is_a?(Account)
                  cname_or_name_or_account
                  # is it a domain name?
                elsif cname_or_name_or_account =~ DOMAIN_REGEXP
                  Account.joins(:domain_names).find_by(domain_names: {
                                                         is_active: true,
                                                         cname: Account.canonical_cname(cname_or_name_or_account)
                                                       })
                else
                  Account.find_by(name: cname_or_name_or_account)
                end
      if account
        Apartment::Tenant.switch!(account.tenant)
      elsif Account.any?
        raise "No tenant found for #{cname_or_name_or_account}"
      else
        Rails.logger.info "It looks like we're in single tenant mode. No tenant found for #{cname_or_name_or_account}"
      end
    end
  end

  def switch!(cname_or_name_or_account)
    self.class.switch!(cname_or_name_or_account)
  end
end
