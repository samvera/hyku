# frozen_string_literal: true

##
# Mode-aware Solr setup for the RSpec suite bootstrap.
#
# Multi-tenant mode (SolrCloud):
#   Calls CreateSolrCollectionJob#without_account to provision named collections
#   via the SolrCloud Collections API, just as the suite has historically done.
#
# Single-tenant mode (standalone Solr):
#   The core is pre-created by the Solr container entrypoint (SOLR_COLLECTION env
#   var in docker-compose.single.yml).  We only verify it is reachable via the
#   Cores STATUS API.  We never call CreateSolrCollectionJob#without_account
#   because that method uses the SolrCloud Collections API which does not exist
#   on a standalone Solr instance.
#
# Called from spec/rails_helper.rb's before(:suite) block.
def prepare_test_solr
  if Hyku.single_tenant?
    ensure_standalone_test_core_available
  else
    CreateSolrCollectionJob.new.without_account('hydra-test') if ENV['IN_DOCKER']
    CreateSolrCollectionJob.new.without_account('hydra-sample')
    CreateSolrCollectionJob.new.without_account('hydra-cross-search-tenant', 'hydra-test, hydra-sample')
  end
end

##
# Checks that the pre-created standalone Solr core is reachable.
# Raises if the core is absent so CI fails fast with a clear message instead of
# producing confusing test failures later.
#
# The core name should have been normalized in spec/rails_helper.rb for single-tenant
# specs: SOLR_COLLECTION is set from SOLR_COLLECTION_TEST so test cleanup never
# points at the development core.
def ensure_standalone_test_core_available
  core = ENV.fetch('SOLR_COLLECTION', ENV.fetch('SOLR_COLLECTION_TEST', 'hydra-test'))
  base_url = ENV.fetch('SOLR_URL', 'http://solr:8983/solr/')
  # Use the base URL without the collection path for the admin endpoint
  admin_base = base_url.sub(%r{/solr/[^/]+/?$}, '/solr/')
  begin
    response = RSolr.connect(url: admin_base).get('/solr/admin/cores', params: { action: 'STATUS', core: core })
    raise "Standalone Solr core #{core.inspect} is missing (STATUS returned no entry)" unless response.dig('status', core)&.any?
    Rails.logger.info "[solr_setup] Standalone Solr core #{core.inspect} verified OK"
  rescue RSolr::Error::ConnectionRefused, RSolr::Error::Http, StandardError => e
    raise "ensure_standalone_test_core_available: cannot reach Solr core #{core.inspect}: #{e.message}"
  end
end
