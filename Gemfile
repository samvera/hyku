source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.1'

gem 'activerecord-nulldb-adapter'
# Use sqlite3 as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 3.12'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
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

  gem 'i18n-debug', require: false
  gem 'i18n-tasks'
  gem 'rspec'
  gem 'rspec-rails', '>= 3.6.0'

  gem 'coveralls', require: false
  gem 'simplecov', require: false

  gem 'fcrepo_wrapper', '~> 0.4'
  gem 'solr_wrapper', '~> 2.0'

  gem 'rubocop', '~> 0.50', '<= 0.52.1'
  gem 'rubocop-rspec', '~> 1.22', '<= 1.22.2'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  # rack-test >= 0.71 does not work with older Capybara versions (< 2.17). See #214 for more details
  gem 'rack-test', '0.7.0'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver'
  gem 'webdrivers', '~> 4.0'
  gem 'webmock'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '>= 3.3.0'

  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.7'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'scss_lint', require: false
end

gem 'blacklight', '~> 6.7'
gem 'blacklight_oai_provider', '~> 6.0'

gem 'hyrax', '~> 2.5.1'
gem 'rsolr', '~> 2.0'

gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'devise-i18n'
gem 'devise_invitable', '~> 1.6'

gem 'apartment'
gem 'config', '~> 1.5', '>= 1.5.1'
gem 'is_it_working'
gem 'rolify'

gem 'flipflop', '~> 2.3'
gem 'lograge'

gem 'zk'

gem 'mods', '~> 2.4'

group :aws, :test do
  gem 'carrierwave-aws'
end

group :aws do
  gem 'active_elastic_job', '~> 2.0'
end

gem 'sidekiq'

gem 'secure_headers'

gem 'honeybadger', '~> 3.0'

gem 'codemirror-rails'
gem 'riiif', '~> 1.1'

gem 'bootstrap-datepicker-rails'
gem 'parser', '~> 2.5.3'
gem 'tether-rails'
