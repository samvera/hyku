# frozen_string_literal: true

class CleanupAccountJob < ApplicationJob
  non_tenant_job

  def perform(account)
    cleanup_solr(account)
    cleanup_fedora(account)
    cleanup_redis(account)
    cleanup_database(account)
    account.destroy
  end

  private

    def cleanup_fedora(account)
      account.fcrepo_endpoint.remove!
    end

    def cleanup_redis(account)
      account.redis_endpoint.remove!
    end

    def cleanup_solr(account)
      account.solr_endpoint.remove!
    end

    def cleanup_database(account)
      Apartment::Tenant.drop(account.tenant)
    rescue StandardError
      nil # ignore if account.tenant missing
    end
end
