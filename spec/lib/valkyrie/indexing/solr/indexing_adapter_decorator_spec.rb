# frozen_string_literal: true

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapterDecorator do
  let(:adapter) { Valkyrie::IndexingAdapter.find(:solr_index) }
  let(:own_connection) { instance_double(RSolr::Client, delete_by_id: nil, delete_by_query: nil, commit: nil) }
  let(:other_tenant_connection) { instance_double(RSolr::Client, delete_by_id: nil, delete_by_query: nil, commit: nil) }

  # The adapter is shared by every thread in the process, as in production.
  around do |example|
    original = adapter.instance_variable_get(:@connection)
    example.run
  ensure
    adapter.instance_variable_set(:@connection, original)
    Thread.current[:indexing_adapter_spec_connection] = nil
  end

  before do
    # Each thread's tenant connection, as SolrEndpoint builds it from the thread's Blacklight config.
    allow(SolrEndpoint).to receive(:new) do
      instance_double(SolrEndpoint, connection: Thread.current[:indexing_adapter_spec_connection])
    end
    Thread.current[:indexing_adapter_spec_connection] = own_connection
    # Another tenant's request switching endpoints, as SolrEndpoint#switch! does.
    Thread.new { adapter.connection = other_tenant_connection }.join
  end

  it "deletes through this thread's tenant connection after another thread switches tenants" do
    adapter.delete(resource: Hyrax::Resource.new(id: Valkyrie::ID.new('solr-delete-probe')))

    expect(own_connection).to have_received(:delete_by_id).with('solr-delete-probe', anything)
    expect(other_tenant_connection).not_to have_received(:delete_by_id)
  end

  it "wipes this thread's tenant index after another thread switches tenants" do
    adapter.wipe!

    expect(own_connection).to have_received(:delete_by_query).with('*:*')
    expect(other_tenant_connection).not_to have_received(:delete_by_query)
  end
end
