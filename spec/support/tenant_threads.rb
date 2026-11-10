# frozen_string_literal: true

module TenantThreads
  # Switches into each account's tenant over and over on its own thread, and returns the distinct
  # results of the block for each account. Every thread switches before any reads, so a setting
  # shared between threads shows up as another tenant's value. One entry per account means its
  # settings never mixed with another tenant's.
  def results_per_tenant(accounts, switches: 10)
    barrier = Concurrent::CyclicBarrier.new(accounts.size)
    seen = Queue.new
    accounts.map do |account|
      Thread.new do
        results = Array.new(switches) do
          Apartment::Tenant.switch!(account.tenant)
          barrier.wait(10)
          yield.tap { barrier.wait(10) }
        end
        seen << [account, results.uniq]
      ensure
        Apartment::Tenant.switch!(Apartment.default_tenant)
      end
    end.each(&:join)
    Array.new(accounts.size) { seen.pop }.to_h
  end
end

RSpec.configure do |config|
  config.include TenantThreads
end
