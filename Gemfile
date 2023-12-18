# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'

gem 'active_elastic_job', github: 'active-elastic-job/active-elastic-job', ref: 'ec51c5d9dedc4a1b47f2db41f26d5fceb251e979', group: %i[aws]
gem 'active-fedora', '~> 14.0'
gem 'activerecord-nulldb-adapter'
gem 'addressable', '2.8.1' # remove once https://github.com/postrank-labs/postrank-uri/issues/49 is fixed
gem 'apartment', github: 'scientist-softserv/apartment', branch: 'development'
gem 'aws-sdk-sqs', group: %i[aws]
gem 'bixby', '~> 5.0', '>= 5.0.2', group: %i[development test]
gem 'blacklight', '~> 7.29'
gem 'blacklight_advanced_search'
gem 'blacklight_oai_provider', '~> 7.0'
gem 'blacklight_range_limit'
gem 'bolognese', '>= 1.9.10'
gem 'bootstrap', '~> 4.6'
gem 'bootstrap-datepicker-rails'
gem 'bulkrax', '~> 5.4'
gem 'byebug', group: %i[development test]
gem 'capybara', group: %i[test]
gem 'capybara-screenshot', '~> 1.0', group: %i[test]
gem 'carrierwave-aws', '~> 1.3', group: %i[aws test]
gem 'cocoon'
gem 'codemirror-rails'
gem 'coffee-rails', '~> 4.2' # Use CoffeeScript for .coffee assets and views
gem 'database_cleaner', group: %i[test]
gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'devise-i18n'
gem 'devise_invitable', '~> 2.0'
gem 'dry-monads', '~> 1.5'
gem 'easy_translate', group: %i[development]
gem 'factory_bot_rails', group: %i[test]
gem 'fcrepo_wrapper', '~> 0.4', group: %i[development test]
gem 'flutie'
gem 'good_job', '~> 2.99'
gem 'googleauth', '= 1.8.1' # 1.9.0 got yanked from rubygems, hard pinning until we can upgrade
gem 'hyrax', github: 'samvera/hyrax', branch: 'double_combo'
gem 'hyrax-doi', github: 'samvera-labs/hyrax-doi', branch: 'rails_hyrax_upgrade'
gem 'hyrax-iiif_av', github: 'samvera-labs/hyrax-iiif_av', branch: 'rails_hyrax_upgrade'
gem 'i18n-debug', require: false, group: %i[development test]
gem 'i18n-tasks', group: %i[development test]
gem 'iiif_print', github: 'scientist-softserv/iiif_print', branch: 'main'
gem 'jbuilder', '~> 2.5'
gem 'jquery-rails' # Use jquery as the JavaScript library
# The maintainers yanked 0.3.2 version (see https://github.com/dryruby/json-canonicalization/issues/2)
gem 'json-canonicalization', "0.3.1"
gem 'launchy', group: %i[test]
gem 'listen', '>= 3.0.5', '< 3.2', group: %i[development]
gem 'lograge'
gem 'mods', '~> 2.4'
gem 'negative_captcha'
gem 'okcomputer'
gem 'omniauth-cas', github: 'stanhu/omniauth-cas', ref: '4211e6d05941b4a981f9a36b49ec166cecd0e271'
gem 'omniauth-multi-provider'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'
gem 'order_already'
gem 'parser', '>= 3.1.0.0'
gem 'pg'
gem 'postrank-uri', '>= 1.0.24'
gem 'pry-byebug', group: %i[development test]
gem 'puma', '~> 5.6' # Use Puma as the app server
gem 'rack-test', '0.7.0', group: %i[test] # rack-test >= 0.71 does not work with older Capybara versions (< 2.17). See #214 for more details
gem 'rails-controller-testing', group: %i[test]
gem 'rdf', '~> 3.2'
gem 'redlock', '>= 0.1.2', '< 2.0' # lock redlock per https://github.com/samvera/hyrax/pull/5961
gem 'riiif', '~> 2.0'
gem 'rolify'
gem 'rsolr', '~> 2.0'
gem 'rspec', group: %i[development test]
gem 'rspec-activemodel-mocks', group: %i[test]
gem 'rspec-its', group: %i[test]
gem 'rspec_junit_formatter', group: %i[test]
gem 'rspec-rails', '>= 3.6.0', group: %i[development test]
gem 'rspec-retry', group: %i[test]
gem 'rubocop', '1.28.2', group: %i[development test]
gem 'rubocop-rails', '~> 2.15', group: %i[development test]
gem 'rubocop-rspec', '~> 1.22', '<= 1.22.2', group: %i[development test]
gem 'sass-rails', '~> 6.0' # Use SCSS for stylesheets
gem 'scss_lint', require: false, group: %i[development]
gem 'secure_headers'
gem 'selenium-webdriver', '4.8.1', group: %i[test]
gem 'shoulda-matchers', '~> 4.0', group: %i[test]
gem 'sidekiq', "< 7.0" # sidekiq 7 requires upgrade to redis 6
gem 'simplecov', require: false, group: %i[development test]
gem 'solr_wrapper', '~> 2.0', group: %i[development test]
gem 'spring', '~> 1.7', group: %i[development]
gem 'spring-watcher-listen', '~> 2.0.0', group: %i[development]
gem 'terser' # to support the Safe Navigation / Optional Chaining operator (?.) and avoid uglifier precompile issue
gem 'tether-rails'
gem 'turbolinks', '~> 5'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'web-console', '>= 3.3.0', group: %i[development] # <%= console %> in views
gem 'webdrivers', '~> 4.7.0', group: %i[test]
gem 'webmock', group: %i[test]

# This gem does nothing by default, but is instead a tool to ease developer flow
# and place overrides, themes and deployment code.
gem 'hyku_knapsack', github: 'samvera-labs/hyku_knapsack', branch: 'upstream_main'

# rubocop:enable Metrics/LineLength
