# frozen_string_literal: true

RSpec.describe 'Hyku reserved redirect prefixes', type: :request do
  # Hyku adds tenant-host routes to Hyrax.config.reserved_redirect_prefixes
  # in config/initializers/hyrax.rb so they cannot be claimed as redirect
  # aliases. This spec verifies those additions are present.

  let(:prefixes) { Hyrax.config.reserved_redirect_prefixes }

  describe 'Hyku-specific prefixes' do
    %w[
      /authorities
      /bookmarks
      /browse
      /exporters
      /identity_providers
      /importers
      /jobs
      /single_signon
      /status
      /sword
    ].each do |prefix|
      it "includes #{prefix}" do
        expect(prefixes).to include(prefix)
      end
    end
  end

  describe 'admin-host-only routes are excluded' do
    # /account and /proprietor are scoped to Account.admin_host via
    # constraints and never reach a tenant host, so they should NOT
    # be reserved on tenant hosts.
    %w[/account /proprietor].each do |prefix|
      it "does not include #{prefix}" do
        expect(prefixes).not_to include(prefix)
      end
    end
  end

  describe 'upstream Hyrax defaults are still present' do
    %w[/admin /dashboard /catalog /concern].each do |prefix|
      it "includes #{prefix}" do
        expect(prefixes).to include(prefix)
      end
    end
  end
end
