#!/usr/bin/env ruby
# frozen_string_literal: true

# Shared by bin/web and bin/worker: sizes DB_POOL from a role-appropriate thread
# count and strips DATABASE_URL's ?pool= so database.yml's DB_POOL stays
# authoritative (the Hyrax Helm chart bakes ?pool= in; see postgresql.poolInUrl).
module DbPoolEnv
  def self.configure!(default_pool:)
    ENV['DB_POOL'] ||= default_pool.to_s
    return unless ENV['DATABASE_URL']

    require 'uri'
    uri = URI.parse(ENV['DATABASE_URL'])
    return unless uri.query

    remaining = URI.decode_www_form(uri.query).reject { |k, _| k == 'pool' }
    uri.query = remaining.empty? ? nil : URI.encode_www_form(remaining)
    ENV['DATABASE_URL'] = uri.to_s
  end
end
