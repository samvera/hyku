# frozen_string_literal: true

class CreateAccountInlineJob < ApplicationJob
  non_tenant_job

  def perform(account)
    CreateSolrCollectionJob.perform_now(account)
    CreateFcrepoEndpointJob.perform_now(account) unless Hyrax.config.disable_wings
    CreateRedisNamespaceJob.perform_now(account)
    account.create_data_cite_endpoint

    # CreateDefaultAdminSetJob.perform_now(account) # handled in Apartment callback
  end
end
