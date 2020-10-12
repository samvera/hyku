# frozen_string_literal: true

class CreateRedisNamespaceJob < ApplicationJob
  non_tenant_job

  def perform(account)
    name = account.tenant.parameterize

    account.create_redis_endpoint(namespace: name)
  end
end
