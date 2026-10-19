# frozen_string_literal: true

RSpec.describe Hyku::S3Migration::Tenants do
  let(:accounts) { [account('one'), account('search'), account('two')] }
  let(:relation) { double('relation') }
  let(:switched) { [] }

  def account(name)
    acct = double(name, name:, cname: "#{name}.example.com", tenant: "#{name}-schema")
    allow(acct).to receive(:switch) { |&block| switched << [:endpoints, name]; block.call } # rubocop:disable Style/Semicolon
    acct
  end

  before do
    allow(relation).to receive(:find_each) { |&block| accounts.each(&block) }
    allow(Account).to receive_messages(all: relation, where: relation)
    allow(Apartment::Tenant).to receive(:switch) { |tenant, &block| switched << [:schema, tenant]; block.call } # rubocop:disable Style/Semicolon
  end

  it 'visits every tenant except the search account' do
    visited = []

    described_class.each { |acct| visited << acct.cname }

    expect(visited).to eq %w[one.example.com two.example.com]
  end

  it 'switches both the database schema and the Solr/Fedora/Redis endpoints' do
    described_class.each(tenants: []) { |_acct| nil }

    expect(switched).to eq [[:schema, 'one-schema'], [:endpoints, 'one'], [:schema, 'two-schema'], [:endpoints, 'two']]
  end

  it 'limits to the given tenants' do
    described_class.each(tenants: ['one.example.com']) { |_acct| nil }

    expect(Account).to have_received(:where).with(cname: ['one.example.com'])
  end

  it 'prefers the account model\'s own search-only flag when it has one' do
    flagged = double('flagged', name: 'x', cname: 'x.example.com', tenant: 'x-schema', search_only?: true)
    allow(relation).to receive(:find_each) { |&block| [flagged].each(&block) }
    visited = []

    described_class.each { |acct| visited << acct.cname }

    expect(visited).to be_empty
  end

  it 'reports a failing tenant and carries on with the rest' do
    errors = []
    visited = []

    failed = described_class.each(on_error: ->(acct, error) { errors << [acct.cname, error.message] }) do |acct|
      raise 'boom' if acct.name == 'one'

      visited << acct.cname
    end

    expect(failed).to eq ['one.example.com']
    expect(errors).to eq [['one.example.com', 'boom']]
    expect(visited).to eq ['two.example.com']
  end
end
