require_relative 'boot'

require 'rails/all'
require 'i18n/debug' if ENV['I18N_DEBUG']

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
groups = Rails.groups
Bundler.require(*groups)

module Hyku
  # Providing a common method to ensure consistent UTF-8 encoding.  Also removing the tricksy Byte
  # Order Marker character which is an invisible 0 space character.
  #
  # @note In testing, we encountered errors with the file's character encoding
  #       (e.g. `Encoding::UndefinedConversionError`).  The following will force the encoding to
  #       UTF-8 and replace any invalid or undefined characters from the original encoding with a
  #       "?".
  #
  #       Given that we still have the original, and this is a derivative, the forced encoding
  #       should be acceptable.
  #
  # @param [String]
  # @return [String]
  #
  # @see https://sentry.io/organizations/scientist-inc/issues/3773392603/?project=6745020&query=is%3Aunresolved&referrer=issue-stream
  # @see https://github.com/samvera-labs/bulkrax/pull/689
  # @see https://github.com/samvera-labs/bulkrax/issues/688
  # @see https://github.com/scientist-softserv/adventist-dl/issues/179
  def self.utf_8_encode(string)
    string
      .encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: "?")
      .delete("\xEF\xBB\xBF")
  end

  class Application < Rails::Application
    ##
    # @!group Class Attributes
    #
    # @!attribute html_head_title
    #   The title to render for the application's HTML > HEAD > TITLE element.
    #   @return [String]
    class_attribute :html_head_title, default: "Hyku", attr_accessor: false

    # @!attribute user_devise_parameters
    #   @return [Object]
    #
    #   This is a value that you want to set in the before_initialize block.
    class_attribute :user_devise_parameters, instance_accessor: false, default: [
                      :database_authenticatable,
                      :invitable,
                      :registerable,
                      :recoverable,
                      :rememberable,
                      :trackable,
                      :validatable,
                      :omniauthable, { omniauth_providers: %i[saml openid_connect cas] }]

    # @!endgroup Class Attributes

    # Add this line to load the lib folder first because we need
    # IiifPrint::SplitPdfs::AdventistPagesToJpgsSplitter
    config.autoload_paths.unshift("#{Rails.root}/lib")

    ##
    #   @return [Array<String>] an array of strings in which we should be looking for theme view
    #           candidates.
    # @see Hyrax::WorksControllerBehavior
    # @see Hyrax::ContactFormController
    # @see Hyrax::PagesController
    # @see https://api.rubyonrails.org/classes/ActionView/ViewPaths.html#method-i-prepend_view_path
    #
    # @see .path_for
    # @see
    def self.theme_view_path_roots
      returning_value = [Rails.root.to_s]
      returning_value.push HykuKnapsack::Engine.root.to_s if defined?(HykuKnapsack)
      returning_value
    end

    ##
    # @api public
    #
    # @param relative_path [String] lookup the relative paths first in the Knapsack then in Hyku.
    #
    # @return [String] the path to the file, favoring those found in the knapsack but falling back
    #         to those in the Rails.root.
    # @see .theme_view_path_roots
    def self.path_for(relative_path)
      if defined?(HykuKnapsack)
        engine_path = HykuKnapsack::Engine.root.join(relative_path)
        return engine_path.to_s if engine_path.exist?
      end

      Rails.root.join(relative_path).to_s
    end

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

      # By default plain text files are not processed for text extraction.  In adding
      # Adventist::TextFileTextExtractionService to the beginning of the services array we are
      # enabling text extraction from plain text files.
      Hyrax::DerivativeService.services = [
        IiifPrint::PluggableDerivativeService
      ]

      # When you are ready to use the derivative rodeo instead of the pluggable uncomment the
      # following and comment out the preceding Hyrax::DerivativeService.service
      #
      # Hyrax::DerivativeService.services = [
      #   Adventist::TextFileTextExtractionService,
      #   IiifPrint::DerivativeRodeoService,
      #   Hyrax::FileSetDerivativesService]

      DerivativeRodeo::Generators::HocrGenerator.additional_tessearct_options = nil

      # Allows us to use decorator files
      Dir.glob(File.join(File.dirname(__FILE__), "../app/**/*_decorator*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Dir.glob(File.join(File.dirname(__FILE__), "../lib/**/*_decorator*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # OAI additions
      Dir.glob(File.join(File.dirname(__FILE__), "../lib/oai/**/*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
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

    # copies tinymce assets directly into public/assets
    config.tinymce.install = :copy
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
