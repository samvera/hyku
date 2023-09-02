# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.5'

gem 'activerecord-nulldb-adapter'
gem 'addressable', '2.8.1' # remove once https://github.com/postrank-labs/postrank-uri/issues/49 is fixed
# Use sqlite3 as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 4.3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'active-fedora', '>= 11.1.4'
gem 'flutie'
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry-byebug'

  gem 'i18n-debug', require: false
  gem 'i18n-tasks'
  gem 'rspec'
  gem 'rspec-rails', '>= 3.6.0'

  gem 'simplecov', require: false

  gem 'fcrepo_wrapper', '~> 0.4'
  gem 'solr_wrapper', '~> 2.0'

  gem 'rubocop', '~> 0.50', '<= 0.52.1'
  gem 'rubocop-rspec', '~> 1.22', '<= 1.22.2'
end

group :test do
  gem 'capybara'
  gem 'capybara-screenshot', '~> 1.0'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  gem 'launchy'
  # rack-test >= 0.71 does not work with older Capybara versions (< 2.17). See #214 for more details
  gem 'rack-test', '0.7.0'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'rspec-its'
  gem 'rspec-retry'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver', '4.8.1'
  gem 'shoulda-matchers', '~> 4.0'
  gem 'webdrivers', '~> 4.7.0'
  gem 'webmock'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '>= 3.3.0'

  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'easy_translate'
  gem 'scss_lint', require: false
  gem 'spring', '~> 1.7'
  gem 'spring-watcher-listen', '~> 2.0.0'
  # gem 'xray-rails' # this gem causes conflicts with sidekiq. Disable when actively using sidekiq.
end

gem 'bulkrax', '~> 5.0'

gem 'blacklight', '~> 6.7'
gem 'blacklight_oai_provider', '~> 6.1', '>= 6.1.1'

gem 'hyrax', '~> 3.5.0'

gem 'bolognese', '>= 1.9.10'
gem 'hyrax-doi', git: 'https://github.com/samvera-labs/hyrax-doi.git', branch: 'main'
gem 'hyrax-iiif_av', git: 'https://github.com/samvera-labs/hyrax-iiif_av.git', branch: 'main'
gem 'iiif_print', git: 'https://github.com/scientist-softserv/iiif_print.git', branch: 'main'
gem 'postrank-uri', '>= 1.0.24'
gem 'redlock', '>= 0.1.2', '< 2.0' # lock redlock per https://github.com/samvera/hyrax/pull/5961
gem 'rsolr', '~> 2.0'

gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'devise-i18n'
gem 'devise_invitable', '~> 1.6'

gem 'apartment'
gem 'is_it_working'
gem 'rolify'

gem 'flipflop', '~> 2.6.0' # waiting for hyrax 4 upgrade
gem 'lograge'

gem 'mods', '~> 2.4'

group :aws, :test do
  gem 'carrierwave-aws', '~> 1.3'
end

group :aws do
  gem 'active_elastic_job', git: 'https://github.com/active-elastic-job/active-elastic-job.git',
                            ref: 'ec51c5d9dedc4a1b47f2db41f26d5fceb251e979'
  gem 'aws-sdk-sqs'
end

gem 'bootstrap-datepicker-rails'
gem "cocoon"
gem 'codemirror-rails'
gem 'negative_captcha'
gem 'okcomputer'
gem 'parser', '~> 2.5.3'
gem 'rdf', '~> 3.1.15' # rdf 3.2.0 removed SerializedTransaction which ldp requires
gem 'riiif', '~> 1.1'
gem 'secure_headers'
gem 'sidekiq', "< 7.0" # sidekiq 7 requires upgrade to redis 6
gem 'terser' # to support the Safe Navigation / Optional Chaining operator (?.) and avoid uglifier precompile issue
gem 'tether-rails'

# When first attempting to upgrade to Hyrax v3.4.2, this dry-monads gem was upgraded to v1.5.0.
# This version threw the following error:
# NameError: uninitialized constant Dry::Monads::Result::Transformer
# Locking it to v1.4.x does not throw an error.
gem 'dry-monads', '~> 1.4.0'
