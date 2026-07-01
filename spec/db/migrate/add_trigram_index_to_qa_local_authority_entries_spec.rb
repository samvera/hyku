# frozen_string_literal: true

require 'rails_helper'

# Regression test for https://github.com/samvera/hyku/actions/runs/28541351737
#
# CreateAccount#create_tenant (app/services/create_account.rb) provisions a new
# tenant with `Apartment::Tenant.create(account.tenant)`, which clones the
# already-migrated schema into a fresh Postgres schema. That's a different code
# path from `db:migrate`'s per-existing-tenant loop, and it does not appear to
# resolve `gin_trgm_ops` the same way `Apartment::Tenant.switch!` does, even
# though the pg_trgm extension itself lives in shared_extensions.
RSpec.describe 'AddTrigramIndexToQaLocalAuthorityEntries', :multitenant do
  let(:tenant) { "trgm_regression_test_#{SecureRandom.hex(4)}" }

  after do
    Apartment::Tenant.drop(tenant)
  rescue Apartment::TenantNotFound
    nil
  end

  it 'provisions a new tenant without raising on the trigram index' do
    expect { Apartment::Tenant.create(tenant) }.not_to raise_error
  end

  it 'creates a usable trigram index in the new tenant' do
    Apartment::Tenant.create(tenant)

    Apartment::Tenant.switch(tenant) do
      indexes = ActiveRecord::Base.connection.indexes('qa_local_authority_entries')
      expect(indexes.map(&:name)).to include('index_qa_local_authority_entries_on_lower_label_trgm')
    end
  end
end
