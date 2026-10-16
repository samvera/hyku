# frozen_string_literal: true

RSpec.describe Hyku::S3Migration::Tenants do
  let(:accounts) do
    [double('a', name: 'pitt', cname: 'pitt.example.com'),
     double('s', name: 'search', cname: 'search.example.com'),
     double('b', name: 'iu', cname: 'iu.example.com')]
  end
  let(:relation) { double('relation') }

  before do
    allow(relation).to receive(:find_each) { |&block| accounts.each(&block) }
    allow(Account).to receive_messages(all: relation, where: relation)
    allow(AccountElevator).to receive(:switch!)
  end

  it 'visits every tenant except the search account' do
    visited = []

    described_class.each { |account| visited << account.cname }

    expect(visited).to eq %w[pitt.example.com iu.example.com]
    expect(AccountElevator).not_to have_received(:switch!).with('search.example.com')
  end

  it 'limits to one tenant when asked' do
    described_class.each(tenant: 'pitt.example.com') { |_account| nil }

    expect(Account).to have_received(:where).with(cname: 'pitt.example.com')
  end

  it 'reports a failing tenant and carries on with the rest' do
    errors = []
    visited = []

    failed = described_class.each(on_error: ->(account, error) { errors << [account.cname, error.message] }) do |account|
      raise 'boom' if account.name == 'pitt'

      visited << account.cname
    end

    expect(failed).to eq ['pitt.example.com']
    expect(errors).to eq [['pitt.example.com', 'boom']]
    expect(visited).to eq ['iu.example.com']
  end
end
