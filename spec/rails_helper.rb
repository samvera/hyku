# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
ENV['HYRAX_FLEXIBLE'] = 'false'
# In test most, unset some variables that can cause trouble
# before booting up Rails
ENV['HYKU_ADMIN_HOST'] = 'test.host'
ENV['HYKU_ROOT_HOST'] = 'test.host'
ENV['HYKU_ADMIN_ONLY_TENANT_CREATION'] = nil
ENV['HYKU_DEFAULT_HOST'] = nil
ENV['HYKU_MULTITENANT'] = 'true'
ENV['VALKYRIE_TRANSITION'] = 'true'
ENV['HYRAX_ANALYTICS_REPORTING'] = 'false'

require 'simplecov'
SimpleCov.start('rails')
require File.expand_path('../config/environment', __dir__)
require 'spec_helper'

# We're going to need this for our factories
require Hyrax::Engine.root.join("lib/hyrax/specs/shared_specs/simple_work.rb").to_s

# I want to set this so that our factory finder will have the right values.
Hyrax.config.admin_set_model = "AdminSetResource"
Hyrax.config.collection_model = "CollectionResource"

# First find the Hyrax factories; then find the local factories (which extend/modify Hyrax
# factories).
FactoryBot.definition_file_paths = [
  Hyrax::Engine.root.join("lib/hyrax/specs/shared_specs/factories").to_s,
  File.expand_path("../factories", __FILE__)
]
FactoryBot.find_definitions

# Appeasing the Hyrax user factory interface.
def RoleMapper.add(user:, groups:)
  groups.each do |group|
    user.add_role(group.to_sym, Site.instance)
  end
end

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rails'
require 'database_cleaner'
require 'active_fedora/cleaner'
require 'webdrivers'
require 'shoulda/matchers'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

# Uses faster rack_test driver when JavaScript support not needed
Capybara.default_max_wait_time = 8
Capybara.default_driver = :rack_test

ENV['WEB_HOST'] ||= `hostname -s`.strip

if ENV['CHROME_HOSTNAME'].present?
  options = Selenium::WebDriver::Options.chrome(args: ["disable-gpu",
                                                       "no-sandbox",
                                                       "whitelisted-ips",
                                                       "window-size=1200,800"])

  Capybara.register_driver :chrome do |app|
    d = Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       capabilities: options,
                                       url: "http://#{ENV['CHROME_HOSTNAME']}:4444/wd/hub")
    # Fix for capybara vs remote files. Selenium handles this for us
    d.browser.file_detector = lambda do |args|
      str = args.first.to_s
      str if File.exist?(str)
    end
    d
  end
  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = 3001
  Capybara.app_host = "http://#{ENV['WEB_HOST']}:#{Capybara.server_port}"
else
  options = Selenium::WebDriver::Options.chrome(args: ["headless",
                                                       "disable-gpu",
                                                       "window-size=1920,1080"])

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      capabilities: options
    )
  end
end

Capybara.javascript_driver = :chrome

# This will ensure that a field named email will not be referred to by a
# hash but by test-email instead. A tool like capybara can now bypass
# this security while still going through the captcha workflow.
NegativeCaptcha.test_mode = true

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.file_fixture_path = Rails.root.join('spec', 'fixtures').to_s

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods
  config.include ApplicationHelper, type: :view
  config.include Warden::Test::Helpers, type: :feature
  config.include ActiveJob::TestHelper

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    Account.destroy_all
    CreateSolrCollectionJob.new.without_account('hydra-test') if ENV['IN_DOCKER']
    CreateSolrCollectionJob.new.without_account('hydra-sample')
    CreateSolrCollectionJob.new.without_account('hydra-cross-search-tenant', 'hydra-test, hydra-sample')
  end

  config.before do |example|
    # make sure we are on the default fedora config
    ActiveFedora::Fedora.reset!
    SolrEndpoint.reset!
    # Pass `:clean' (or hyrax's convention of :clean_repo) to destroy objects in fedora/solr and
    # start from scratch
    if example.metadata[:clean] || example.metadata[:clean_repo] || example.metadata[:type] == :feature
      ## We don't need to do `Hyrax::SolrService.wipe!` so long as we're using `ActiveFedora.clean!`;
      ## but Valkyrie is coming so be prepared.
      # Hyrax::SolrService.wipe!
      ActiveFedora::Cleaner.clean!
    end

    # Only use truncation for JS-enabled feature specs
    if example.metadata[:js] && example.metadata[:type] == :feature
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end
  end

  config.after(:each, type: :feature) do |example|
    # rubocop:disable Lint/Debugger
    save_page if example.exception.present?
    # rubocop:enable Lint/Debugger
    Warden.test_reset!
    Capybara.reset_sessions!
    page.driver.reset!
  end

  config.after do
    DatabaseCleaner.clean
  rescue StandardError => e
    Rails.logger.error "DatabaseCleaner error: #{e.message}"
    # Only switch to truncation if we hit a deadlock
    raise e unless e.message.include?('deadlock detected')
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
