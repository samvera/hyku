# frozen_string_literal: true

namespace :hyku do
  namespace :flexible_schema do
    desc 'Create default flexible schema for each full (non-search-only) tenant unless one already exists'
    task initialize: :environment do
      Account.full_accounts.each do |account|
        switch!(account)
        puts "Initializing flexible schema for tenant: #{account.cname}"
        Hyrax::FlexibleSchema.create_default_schema
      end
    end
  end
end
