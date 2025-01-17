# frozen_string_literal: true
require_relative 'boot'
require_relative '../app/middleware/no_cache_middleware'

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
  # @see https://github.com/notch8/adventist-dl/issues/179
  def self.utf_8_encode(string)
    string
      .encode(Encoding.find('UTF-8'), invalid: :replace, undef: :replace, replace: "?")
      .delete("\xEF\xBB\xBF")
  end

  def self.bulkrax_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_BULKRAX_ENABLED', true))
  end

  def self.default_bulkrax_field_mappings=(value)
    err_msg = 'Hyku.default_bulkrax_field_mappings must respond to #with_indifferent_access'
    raise err_msg unless value.respond_to?(:with_indifferent_access)

    @default_bulkrax_field_mappings = value.with_indifferent_access
  end

  # This represents the default Bulkrax field mappings that new Accounts will be initialized with.
  # Bulkrax field mappings should not be configured within the Bulkrax initializer in Hyku.
  # @see lib/bulkrax/bulkrax_decorator.rb
  # @see https://github.com/samvera/bulkrax/wiki/Configuring-Bulkrax#field-mappings
  def self.default_bulkrax_field_mappings
    return @default_bulkrax_field_mappings if @default_bulkrax_field_mappings.present?

    default_bulkrax_fm = {}
    defaults = {
      'abstract' => { from: ['abstract'], split: true },
      'accessibility_feature' => { from: ['accessibility_feature'], split: '\|' },
      'accessibility_hazard' => { from: ['accessibility_hazard'], split: '\|' },
      'accessibility_summary' => { from: ['accessibility_summary'] },
      'additional_information' => { from: ['additional_information'], split: '\|', generated: true },
      'admin_note' => { from: ['admin_note'] },
      'admin_set_id' => { from: ['admin_set_id'], generated: true },
      'alternate_version' => { from: ['alternate_version'], split: '\|' },
      'alternative_title' => { from: ['alternative_title'], split: '\|', generated: true },
      'arkivo_checksum' => { from: ['arkivo_checksum'], split: '\|', generated: true },
      'audience' => { from: ['audience'], split: '\|' },
      'based_near' => { from: ['location'], split: '\|' },
      'bibliographic_citation' => { from: ['bibliographic_citation'], split: true },
      'contributor' => { from: ['contributor'], split: true },
      'create_date' => { from: ['create_date'], split: true },
      'children' => { from: ['children'], related_children_field_mapping: true },
      'committee_member' => { from: ['committee_member'], split: '\|' },
      'creator' => { from: ['creator'], split: true },
      'date_created' => { from: ['date_created'], split: true },
      'date_uploaded' => { from: ['date_uploaded'], generated: true },
      'degree_discipline' => { from: ['discipline'], split: '\|' },
      'degree_grantor' => { from: ['grantor'], split: '\|' },
      'degree_level' => { from: ['level'], split: '\|' },
      'degree_name' => { from: ['degree'], split: '\|' },
      'depositor' => { from: ['depositor'], split: '\|', generated: true },
      'description' => { from: ['description'], split: true },
      'discipline' => { from: ['discipline'], split: '\|' },
      'education_level' => { from: ['education_level'], split: '\|' },
      'embargo_id' => { from: ['embargo_id'], generated: true },
      'extent' => { from: ['extent'], split: true },
      'file' => { from: ['file'], split: /\s*[|]\s*/ },
      'identifier' => { from: ['identifier'], split: true },
      'import_url' => { from: ['import_url'], split: '\|', generated: true },
      'keyword' => { from: ['keyword'], split: true },
      'label' => { from: ['label'], generated: true },
      'language' => { from: ['language'], split: true },
      'lease_id' => { from: ['lease_id'], generated: true },
      'library_catalog_identifier' => { from: ['library_catalog_identifier'], split: '\|' },
      'license' => { from: ['license'], split: /\s*[|]\s*/ },
      'modified_date' => { from: ['modified_date'], split: true },
      'newer_version' => { from: ['newer_version'], split: '\|' },
      'oer_size' => { from: ['oer_size'], split: '\|' },
      'on_behalf_of' => { from: ['on_behalf_of'], generated: true },
      'owner' => { from: ['owner'], generated: true },
      'parents' => { from: ['parents'], related_parents_field_mapping: true },
      'previous_version' => { from: ['previous_version'], split: '\|' },
      'publisher' => { from: ['publisher'], split: true },
      'related_item' => { from: ['related_item'], split: '\|' },
      'relative_path' => { from: ['relative_path'], split: '\|', generated: true },
      'related_url' => { from: ['related_url', 'relation'], split: /\s* [|]\s*/ },
      'remote_files' => { from: ['remote_files'], split: /\s*[|]\s*/ },
      'rendering_ids' => { from: ['rendering_ids'], split: '\|', generated: true },
      'resource_type' => { from: ['resource_type'], split: true },
      'rights_holder' => { from: ['rights_holder'], split: '\|' },
      'rights_notes' => { from: ['rights_notes'], split: true },
      'rights_statement' => { from: ['rights', 'rights_statement'], split: '\|', generated: true },
      'source' => { from: ['source'], split: true },
      'state' => { from: ['state'], generated: true },
      'subject' => { from: ['subject'], split: true },
      'table_of_contents' => { from: ['table_of_contents'], split: '\|' },
      'title' => { from: ['title'], split: /\s*[|]\s*/ },
      'video_embed' => { from: ['video_embed'] }
    }

    default_bulkrax_fm['Bulkrax::BagitParser'] = defaults.merge({
                                                                  # add or remove custom mappings for this parser here
                                                                })

    default_bulkrax_fm['Bulkrax::CsvParser'] = defaults.merge({
                                                                # add or remove custom mappings for this parser here
                                                              })

    default_bulkrax_fm['Bulkrax::OaiDcParser'] = defaults.merge({
                                                                  # add or remove custom mappings for this parser here
                                                                })

    default_bulkrax_fm['Bulkrax::OaiQualifiedDcParser'] = defaults.merge({
                                                                           # add or remove custom mappings for this parser here
                                                                         })

    default_bulkrax_fm['Bulkrax::XmlParser'] = defaults.merge({
                                                                # add or remove custom mappings for this parser here
                                                              })

    default_bulkrax_fm.with_indifferent_access
  end

  # rubocop:disable Metrics/ClassLength
  class Application < Rails::Application
    ##
    # @!group Class Attributes
    #
    # @!attribute html_head_title
    #   The title to render for the application's HTML > HEAD > TITLE element.
    #   @return [String]
    class_attribute :html_head_title, default: "Hyku", instance_accessor: false

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
      :omniauthable, { omniauth_providers: %i[saml openid_connect cas] }
    ]

    ##
    # @!attribute iiif_audio_labels_and_mime_types [r|w]
    #   @see Hyrax::IiifAv::DisplaysContentDecorator
    #   @return [Hash<String,String>] Hash of valid audio labels and their mime types.
    class_attribute :iiif_audio_labels_and_mime_types, default: { "ogg" => "audio/ogg", "mp3" => "audio/mpeg" }

    ##
    # @!attribute iiif_video_labels_and_mime_types [r|w]
    #   @see Hyrax::IiifAv::DisplaysContentDecorator
    #   @return [Hash<String,String>] Hash of valid video labels and their mime types.
    class_attribute :iiif_video_labels_and_mime_types, default: { "mp4" => "video/mpeg", "webm" => "audio/webm" }

    ##
    # @!attribute iiif_video_url_builder [r|w]
    #   @param document [SolrDocument]
    #   @param label [String]
    #   @param host [String] (e.g. samvera.org)
    #   @return [String] the fully qualified URL.
    #   @see Hyrax::IiifAv::DisplaysContentDecorator
    #
    #   @example
    #     # The below example will build a URL taht will download directly from Hyrax as the
    #     # video resource.  This is a hack to address the processing times of video derivatives;
    #     # namely in certain setups/configurations of Hyku, video processing is laggy—as in days.
    #     #
    #     # The draw back of using this method is that we're pointing to the original video file.
    #     # This is acceptable if the original file has already been processed out of band (e.g.
    #     # before uploading to Hyku/Hyrax).  When we're dealing with a raw video, this is likely
    #     # not ideal for streaming.
    #     Hyrax::IiifAv::DisplaysContent.iiif_video_url_builder = ->(document:, label:, host:) do
    #       Hyrax::Engine.routes.url_helpers.download_url(document, host:, protocol: 'https')
    #     end
    class_attribute :iiif_video_url_builder,
                    default: ->(document:, label:, host:) { Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(document.id, label:, host:) }

    ##
    # @!attribute iiif_audio_url_builder [r|w]
    #   @param document [SolrDocument]
    #   @param label [String]
    #   @param host [String] (e.g. samvera.org)
    #   @return [String] the fully qualified URL.
    #   @see Hyrax::IiifAv::DisplaysContentDecorator
    #
    #   @example
    #     # The below example will build a URL taht will download directly from Hyrax as the
    #     # audio resource.  This is a hack to address the processing times of audio derivatives;
    #     # namely in certain setups/configurations of Hyku, audio processing is laggy.
    #     #
    #     # The draw back of using this method is that we're pointing to the original audio file.
    #     # This is acceptable if the original file has already been processed out of band (e.g.
    #     # before uploading to Hyku/Hyrax).  When we're dealing with a raw audio, this may not
    #     # be ideal for streaming.
    #     Hyrax::IiifAv::DisplaysContent.iiif_audio_url_builder = ->(document:, label:, host:) do
    #       Hyrax::Engine.routes.url_helpers.download_url(document, host:, protocol: 'https')
    #     end
    class_attribute :iiif_audio_url_builder,
                    default: ->(document:, label:, host:) { Hyrax::IiifAv::Engine.routes.url_helpers.iiif_av_content_url(document.id, label:, host:) }
    # @!endgroup Class Attributes

    # Add this line to load the lib folder first because we need
    # IiifPrint::SplitPdfs::AdventistPagesToJpgsSplitter
    config.autoload_paths.unshift(Rails.root.join('lib'))

    # Add the middleware directory to the eager load paths
    config.eager_load_paths << Rails.root.join('app', 'middleware')

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
      returning_value.unshift HykuKnapsack::Engine.root.to_s if defined?(HykuKnapsack)
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

    ##
    # Because of Hyku using the Goddess adapter of Hyrax 5.x, we want to have a
    # canonical answer for what are the Work Types that we want to manage.
    #
    # We don't want to rely on `Hyrax.config.curation_concerns`, as these are
    # the ActiveFedora implementations.
    #
    # @return [Array<Class>]
    def self.work_types
      Hyrax.config.curation_concerns.map do |cc|
        if cc.to_s.end_with?("Resource")
          cc
        else
          # We may encounter a case where we don't have an old ActiveFedora
          # model that we're mapping to.  For example, let's say we add Game as
          # a curation concern.  And Game has only ever been written/modeled via
          # Valkyrie.  We don't want to also have a GameResource.
          "#{cc}Resource".safe_constantize || cc
        end
      end
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Gzip all responses.  We probably could do this in an upstream proxy, but
    # configuring Nginx on Elastic Beanstalk is a pain.
    config.middleware.use Rack::Deflater

    # The locale is set by a query parameter, so if it's not found render 404
    config.action_dispatch.rescue_responses["I18n::InvalidLocale"] = :not_found

    if defined?(ActiveElasticJob) && ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', '') == 'elastic'
      Rails.application.configure do
        process_jobs = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ELASTIC_JOBS', false))
        config.active_elastic_job.process_jobs = process_jobs
        config.active_elastic_job.aws_credentials = -> { Aws::InstanceProfileCredentials.new }
        config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
      end
    end

    config.to_prepare do
      # Load locales early so decorators can use them during initialization
      I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml')]

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

      if Hyku.bulkrax_enabled?
        # set bulkrax default work type to first curation_concern if it isn't already set
        Bulkrax.default_work_type = Hyku::Application.work_types.first.to_s if Bulkrax.default_work_type.blank?
        Bulkrax.collection_model_class = Hyrax.config.collection_class
        Bulkrax.file_model_class = Hyrax.config.file_set_class
      end

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
      begin
        TenantMaintenanceJob.perform_later unless ActiveJob::Base.find_job(klass: TenantMaintenanceJob)
      rescue
        Rails.logger.error('No background job queue connection, skipping add of TenantMaintenanceJob')
      end
    end

    # When running tests we don't want to auto-specify factories
    config.factory_bot.definition_file_paths = [] if config.respond_to?(:factory_bot)

    # resolve reloading issue in dev mode
    config.paths.add 'app/helpers', eager_load: true

    config.before_initialize do
      if defined?(ActiveElasticJob) && ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', '') == 'elastic'
        Rails.application.configure do
          process_jobs = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ELASTIC_JOBS', false))
          config.active_elastic_job.process_jobs = process_jobs
          config.active_elastic_job.aws_credentials = -> { Aws::InstanceProfileCredentials.new }
          config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
        end
      end

      Object.include(AccountSwitch)
    end

    config.autoload_paths << Rails.root.join("app", "controllers", "api")

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
      yaml_column_permitted_classes = [
        Symbol,
        Hash,
        Array,
        ActiveSupport::HashWithIndifferentAccess,
        ActiveModel::Attribute.const_get(:FromDatabase),
        User,
        Time
      ]
      config.active_record.yaml_column_permitted_classes = yaml_column_permitted_classes
      # Seems at some point `ActiveRecord::Base.yaml_column_permitted_classes` loses all the values we set above
      # so we need to set it again here.
      ActiveRecord::Base.yaml_column_permitted_classes = yaml_column_permitted_classes

      # Because we're loading local translations early in the to_prepare block for our decorators,
      # the I18n.load_path is out of order.  This line ensures that we load local translations last.
      I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.yml')]

      ##
      # The first "#valid?" service is the one that we'll use for generating derivatives.
      Hyrax::DerivativeService.services = [
        IiifPrint::TenantConfig::DerivativeService,
        Hyrax::FileSetDerivativesService
      ]

      ##
      # This needs to be in the after initialize so that the IiifPrint gem can do it's decoration.
      #
      # @see https://github.com/notch8/iiif_print/blob/9e7837ce4bd08bf8fff9126455d0e0e2602f6018/lib/iiif_print/engine.rb#L54 Where we do the override.
      Hyrax::Actors::FileSetActor.prepend(IiifPrint::TenantConfig::FileSetActorDecorator)
      Hyrax::WorkShowPresenter.prepend(IiifPrint::TenantConfig::WorkShowPresenterDecorator)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
