# frozen_string_literal: true

# Counts SQL queries rather than wall-clock time so this can't flake on CI runner load.
RSpec.describe "A work's show page query count", type: :request, clean: true, multitenant: true do
  def count_queries(&block)
    count = 0
    counter = ->(*, **) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end

  let(:account) { create(:account) }
  let(:work) { create(:work, visibility: 'open') }

  before do
    WebMock.disable!
    Apartment::Tenant.create(account.tenant)
    Apartment::Tenant.switch(account.tenant) do
      Site.update(account:)
      work
    end
  end

  after do
    WebMock.enable!
    Apartment::Tenant.drop(account.tenant)
  end

  it 'does not regress the number of SQL queries for an anonymous view of an open work' do
    queries = count_queries { get "http://#{account.cname}/concern/generic_works/#{work.id}" }
    expect(response.status).to eq(200)

    puts "Queries for work show (anon): #{queries}"

    # Measured at 89 queries as of this writing; 120 leaves headroom for minor variation.
    expect(queries).to be < 120
  end
end
