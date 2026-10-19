# frozen_string_literal: true

module Hyku
  module S3Migration
    # Runs a block inside each tenant (or the given ones, by cname), skipping search-only accounts.
    # A failure in one tenant is reported to on_error and the loop carries on.
    #
    # Switching a tenant takes two steps: Apartment switches the database schema (where Valkyrie
    # resources live), and Account#switch points Solr, Fedora and Redis at the tenant. Either one alone
    # leaves queries or indexing aimed at the wrong tenant.
    module Tenants
      # @return [Array<String>] cnames of tenants that raised
      def self.each(tenants: [], on_error: ->(_account, _error) {})
        accounts = tenants.present? ? Account.where(cname: tenants) : Account.all
        failed = []
        accounts.find_each do |account|
          next if skip?(account)

          Apartment::Tenant.switch(account.tenant) { account.switch { yield account } }
        rescue StandardError => e
          on_error.call(account, e)
          failed << account.cname
        end
        failed
      end

      def self.skip?(account)
        account.respond_to?(:search_only?) ? account.search_only? : account.name == 'search'
      end
    end
  end
end
