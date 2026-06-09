# frozen_string_literal: true

module Hyku
  ##
  # Returns true when the app is running in multi-tenant mode
  # (i.e. HYKU_MULTITENANT is set to a truthy value).
  #
  # This is the single source of truth for mode detection across
  # Ruby code, jobs, and specs.  Never scatter raw ENV checks for
  # HYKU_MULTITENANT — call these helpers instead.
  def self.multitenant?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false))
  end

  ##
  # Returns true when the app is running in single-tenant mode
  # (HYKU_MULTITENANT is absent or falsy).
  #
  # In single-tenant mode:
  #   - Solr is a standalone instance; no SolrCloud Collections API calls.
  #   - The Solr core is pre-created by the container entrypoint (SOLR_COLLECTION env var).
  #   - CreateSolrCollectionJob only sets the SolrEndpoint URL; it never calls /solr/admin/collections.
  #   - RemoveSolrCollectionJob is a no-op (the shared core must not be deleted per-account).
  def self.single_tenant?
    !multitenant?
  end
end
