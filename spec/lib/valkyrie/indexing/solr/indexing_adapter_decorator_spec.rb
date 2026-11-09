# frozen_string_literal: true

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapterDecorator do
  let(:adapter) { Valkyrie::IndexingAdapter.find(:solr_index) }
  let(:own_connection) { instance_double(RSolr::Client, delete_by_id: nil, delete_by_query: nil, commit: nil) }
  let(:other_tenant_connection) { instance_double(RSolr::Client, delete_by_id: nil, delete_by_query: nil, commit: nil) }

  def in_thread(&block)
    Thread.new(&block).value
  end

  it "deletes through this thread's tenant connection after another thread switches tenants" do
    in_thread do
      adapter.connection = own_connection
      in_thread { adapter.connection = other_tenant_connection }
      adapter.delete(resource: Hyrax::Resource.new(id: Valkyrie::ID.new('solr-delete-probe')))
    end

    expect(own_connection).to have_received(:delete_by_id).with('solr-delete-probe', anything)
    expect(other_tenant_connection).not_to have_received(:delete_by_id)
  end

  it "wipes this thread's tenant index after another thread switches tenants" do
    in_thread do
      adapter.connection = own_connection
      in_thread { adapter.connection = other_tenant_connection }
      adapter.wipe!
    end

    expect(own_connection).to have_received(:delete_by_query).with('*:*')
    expect(other_tenant_connection).not_to have_received(:delete_by_query)
  end

  it "keeps the core this thread switched to when another thread switches to another tenant" do
    core = in_thread do
      SolrEndpoint.new(url: 'http://solr.example/solr/tenant-a', collection: 'tenant-a').switch!
      in_thread { SolrEndpoint.new(url: 'http://solr.example/solr/tenant-b', collection: 'tenant-b').switch! }
      adapter.connection.uri.path
    end

    expect(core).to end_with('/tenant-a/')
  end

  it "builds the default connection for a thread that has not switched" do
    allow(SolrEndpoint).to receive(:new).and_return(instance_double(SolrEndpoint, connection: own_connection))

    expect(in_thread { adapter.connection }).to eq own_connection
  end
end
