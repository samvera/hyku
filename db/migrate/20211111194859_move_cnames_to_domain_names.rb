class MoveCnamesToDomainNames < ActiveRecord::Migration[5.2]
  def change
    Account.find_each do |a|
      next if a.domain_names.count > 0
      a.domain_names << DomainName.create(cname: a.cname, is_active: true, is_ssl_enabled: true)
    end
  end
end