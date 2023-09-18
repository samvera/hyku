require_relative 'boot'

require 'rails/all'
require 'i18n/debug' if ENV['I18N_DEBUG']

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
groups = Rails.groups
Bundler.require(*groups)

module Hyku
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Gzip all responses.  We probably could do this in an upstream proxy, but
    # configuring Nginx on Elastic Beanstalk is a pain.
    config.middleware.use Rack::Deflater

    # The locale is set by a query parameter, so if it's not found render 404
    config.action_dispatch.rescue_responses.merge!(
      "I18n::InvalidLocale" => :not_found
    )

    if defined?(ActiveElasticJob) && ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', '') == 'elastic'
      Rails.application.configure do
        process_jobs = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ELASTIC_JOBS', false))
        config.active_elastic_job.process_jobs = process_jobs
        config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
        config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
      end
    end

    config.to_prepare do
      # Allows us to use decorator files in the app directory
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare do
      # Allows us to use decorator files in the app directory
      Dir.glob(File.join(File.dirname(__FILE__), "../lib/**/*_decorator*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # OAI additions
    Dir.glob(File.join(File.dirname(__FILE__), "../lib/oai/**/*.rb")).sort.each do |c|
      Rails.configuration.cache_classes ? require(c) : load(c)
    end

    # resolve reloading issue in dev mode
    config.paths.add 'app/helpers', eager_load: true

    config.before_initialize do
      if defined?(ActiveElasticJob) && ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', '') == 'elastic'
        Rails.application.configure do
          process_jobs = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ELASTIC_JOBS', false))
          config.active_elastic_job.process_jobs = process_jobs
          config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
          config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
        end
      end

      Object.include(AccountSwitch)
    end

    ##
    # Psych Allow YAML Classes
    #
    # The following configuration addresses errors of the following form:
    #
    # ```
    # Psych::DisallowedClass: Tried to load unspecified class: ActiveSupport::HashWithIndifferentAccess
    # ```
    #
    # Psych::DisallowedClass: Tried to load unspecified class: <Your Class Name Here>
    config.after_initialize do
      config.active_record.yaml_column_permitted_classes = [
        Symbol,
        Hash,
        Array,
        ActiveSupport::HashWithIndifferentAccess,
        ActiveModel::Attribute.const_get(:FromDatabase),
        User,
        Time
      ]
    end
  end
end
