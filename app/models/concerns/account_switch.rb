# frozen_string_literal: true

module AccountSwitch
  extend ActiveSupport::Concern

  class_methods do
    def switch!(cname_or_name_or_account)
      account = if cname_or_name_or_account.is_a?(Account)
                  cname_or_name_or_account
                  # is it a domain name?
                elsif cname_or_name_or_account =~ /^((?!-)[A-Za-z0-9-]{1, 63}(?<!-)\\.)+[A-Za-z]{2, 6}$”/
                  Account.joins(:domain_names).find_by(domain_names: {
                                                         is_active: true, cname: Account.canonical_cname(cname)
                                                       })
                else
                  Account.find_by(name: cname_or_name_account)
                end
      if account
        Apartment::Tenant.switch!(account.tenant)
      elsif Account.any?
        raise "No tenant found for #{cname}"
      else
        Rails.logger.info "It looks like we're in single tenant mode. No tenant found for #{cname}"
      end
    end
  end

  def switch!(cname_or_name_or_account)
    self.class.switch!(cname_or_name_or_account)
  end
end
