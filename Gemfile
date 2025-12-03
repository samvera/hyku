# frozen_string_literal: true

# for knapsack overrides of gems. See https://github.com/ManageIQ/bundler-inject
# bundler inject reads from ~/.bundler.d and ./bundler.d  ~/.bundler.d maps to the bundler.d directory in your knapsack.
plugin 'bundler-inject'
begin
  require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject")
rescue
  nil
end

# rubocop:disable Layout/LineLength
source 'https://rubygems.org'

# Updated to Rails 7.2 for upgrade
gem 'rails', '~> 7.2.0'

gem 'active-fedora'
gem 'activerecord-nulldb-adapter'
gem 'activesupport', '>= 4.2.0', group: %i[development test]
gem 'addressable', '2.8.1' # remove once https://github.com/postrank-labs/postrank-uri/issues/49 is fixed
gem 'aws-sdk-sqs', group: %i[aws]
gem 'bixby', group: %i[development test]
gem 'blacklight', '~> 7.38' # Updated for Rails 7.2 compatibility
gem 'blacklight_advanced_search'
gem 'blacklight_oai_provider', '~> 7.0'
gem 'blacklight_range_limit', '~> 8.5'
gem 'bolognese', '>= 1.9.10'
gem 'bootstrap', '~> 4.6'
gem 'bootstrap-datepicker-rails'
gem 'bulkrax', '~> 9.3.0'
gem 'byebug', group: %i[development test]
gem 'capybara', group: %i[test]
gem 'capybara-screenshot', '~> 1.0', group: %i[test]
gem 'carrierwave-aws', '~> 1.3', group: %i[aws test]
gem 'cocoon'
gem 'codemirror-rails'
gem 'coffee-rails', '~> 4.2' # Use CoffeeScript for .coffee assets and views
gem 'database_cleaner', group: %i[test]
gem 'derivative-rodeo', '~>0.5', '>= 0.5.3'
gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'devise-i18n'
gem 'devise_invitable', '~> 2.0'
gem 'dry-monads', '~> 1.5'
gem 'easy_translate', group: %i[development]
gem 'factory_bot_rails', group: %i[test]
gem 'fcrepo_wrapper', '~> 0.4', group: %i[development test]
gem 'flutie'
gem 'good_job', '~> 4.10' # Updated for Rails 7.2 compatibility
gem 'googleauth', '~> 1.9.0'
gem 'google-protobuf'
gem 'grpc'
gem 'hyrax', github: 'samvera/hyrax', branch: 'main'
gem 'hyrax-doi', github: 'samvera-labs/hyrax-doi', branch: 'rails_hyrax_upgrade'
gem 'hyrax-iiif_av', github: 'samvera-labs/hyrax-iiif_av', branch: 'rails_hyrax_upgrade'
gem 'i18n-debug', require: false, group: %i[development test]
gem 'i18n-tasks', group: %i[development test]
gem 'iiif_print', '~> 3.0.10'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails' # Use jquery as the JavaScript library
gem 'json-canonicalization', "0.3.1" # The maintainers yanked 0.3.2 version (see https://github.com/dryruby/json-canonicalization/issues/2)
gem 'json_schemer' # Required for m3 schema validation
gem 'launchy', group: %i[test]
gem 'listen', group: %i[development]
gem 'lograge'
gem 'mods', '~> 2.4'
gem 'negative_captcha'
gem 'okcomputer'
gem 'omniauth-cas', github: 'stanhu/omniauth-cas', ref: '4211e6d05941b4a981f9a36b49ec166cecd0e271'
gem 'omniauth-multi-provider'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'
gem 'openssl', '>= 3.2.0'
gem 'order_already', '~> 0.3.2'
gem 'parser', '>= 3.1.0.0'
gem 'pg'
gem 'postrank-uri', '>= 1.0.24'
gem 'pry-byebug', group: %i[development test]
gem 'pry-rails'
gem 'puma', '~> 5.6' # Use Puma as the app server
gem 'qa', git: 'https://github.com/samvera/questioning_authority.git', branch: 'main'
gem 'rack-attack'
gem 'rack-test', '0.7.0', group: %i[test] # rack-test >= 0.71 does not work with older Capybara versions (< 2.17). See #214 for more details
gem 'rails-controller-testing', group: %i[test]
gem 'rdf', '~> 3.2'
gem 'redcarpet' # for Markdown constant
gem 'redis-actionpack'
gem 'redis-namespace', '~> 1.10' # Hyrax v5 relies on 1.5; but we'd like to have the #clear method so we need 1.10 or greater.
gem 'redlock', '>= 0.1.2', '< 2.0' # lock redlock per https://github.com/samvera/hyrax/pull/5961
gem 'riiif', git: 'https://github.com/sul-dlss/riiif.git', ref: '9a375'
gem 'rolify'
gem 'ros-apartment', require: 'apartment' # Rails 7.2 compatible apartment fork - drop-in replacement
gem 'rsolr', '~> 2.0'
gem 'rspec', group: %i[development test]
gem 'rspec-activemodel-mocks', group: %i[test]
gem 'rspec-its', group: %i[test]
gem 'rspec_junit_formatter', group: %i[test]
gem 'rspec-rails', '>= 3.6.0', group: %i[development test]
gem 'rspec-retry', group: %i[test]
gem 'rubocop', '~> 1.61.0', group: %i[development test]
gem 'rubocop-capybara', group: %i[development test]
gem 'rubocop-factory_bot', group: %i[development test]
gem 'rubocop-rails', '~> 2.15', group: %i[development test]
gem 'rubocop-rspec', '~> 1.22', '<= 1.22.2', group: %i[development test]
gem 'sass-rails', '~> 6.0' # Use SCSS for stylesheets
gem 'scss_lint', require: false, group: %i[development]
gem 'secure_headers'
gem 'selenium-webdriver', '~> 4.8', group: %i[test] # Updated for Rails 7.2 compatibility
gem 'shoulda-matchers', '~> 4.0', group: %i[test]
gem 'sidekiq', '~> 7.0' # Updated for Rails 7.2 - REQUIRES Redis 6.2+ (check infrastructure)
gem 'simplecov', require: false, group: %i[development test]
gem 'solargraph', group: %i[development]
gem 'solr_wrapper', '~> 2.0', group: %i[development test]
gem 'spring', '~> 1.7', group: %i[development]
gem 'spring-watcher-listen', '~> 2.0.0', group: %i[development]
gem 'sprockets-rails' # Explicitly required for Rails 7.2 (no longer default dependency)
gem 'terser' # to support the Safe Navigation / Optional Chaining operator (?.) and avoid uglifier precompile issue
gem 'tether-rails'
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'valkyrie', '~> 3.0', '>= 3.1.4' # There's a patch in 3.1.4 that we want
gem 'valkyrie-shrine'
gem 'web-console', '>= 3.3.0', group: %i[development] # <%= console %> in views
gem 'webdrivers', '~> 4.7.0', group: %i[test]
gem 'webmock', group: %i[test]
gem 'willow_sword', github: 'notch8/willow_sword', branch: 'main'

# Enabling the following gem breaks sidekiq. To Enable: assets.debug must be set to true in config/development.rb
# gem "xray-rails", git: "https://github.com/brentd/xray-rails.git", branch: "bugs/ruby-3.0.0", group: %i[development]

# This gem does nothing by default, but is instead a tool to ease developer flow
# and place overrides, themes and deployment code.
#
# When you use a knapsack for Hyku development, which we recommend, you'll want to ensure that your
# local knapsack repository has a `'required_for_knapsack_instances'` branch (which it should by
# default).  Due to some tomfoolery, of knapsack, the branch name
# (e.g. `required_for_knapsack_instances`) must be checked out locally in the knapsack environment
# that you use to build Docker.
#
# Why not use `main`?  We need a stable SHA for building HykuKnapsack prime
# (e.g. samvera-labs/hyku_knapsack).  Why the stable SHA?  Because when we bundle a knapsack, the
# Hyku submodule uses the SHA of the locally checked out branch specified in the gem spec.  Which
# can create a chicken and egg issue; namely I need to update Hyku with a new SHA for Knapsack, but
# to update Knapsack's submodule reference to Hyku, I need a new SHA for knapsack.  Thus, I can never
# use a "regular branch".  Instead we need to use a separate more stable for Knapsack.
#
# Thus the hopefully descriptive `required_for_knapsack_instances`.
#
# tl;dr - Have a local `required_for_knapsack_instances` branch on your knapsack repository and 99%
#         of the time use the `samvera-labs/hyku_knapsack` remote branch.
gem 'hyku_knapsack', github: 'samvera-labs/hyku_knapsack', branch: 'required_for_knapsack_instances'

# rubocop:enable Metrics/MethodLength
