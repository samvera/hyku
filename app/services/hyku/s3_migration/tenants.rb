# frozen_string_literal: true

module Hyku
  module S3Migration
    # Runs a block inside each tenant (or one, by cname), skipping the cross-tenant "search"
    # account. A failure in one tenant is reported to on_error and the loop carries on.
    module Tenants
      module_function

      # @return [Array<String>] cnames of tenants that raised
      def each(tenant: nil, on_error: ->(_account, _error) {})
        accounts = tenant.present? ? Account.where(cname: tenant) : Account.all
        failed = []
        accounts.find_each do |account|
          next if account.name == 'search'

          AccountElevator.switch!(account.cname)
          yield account
        rescue StandardError => e
          on_error.call(account, e)
          failed << account.cname
        end
        failed
      end
    end
  end
end
