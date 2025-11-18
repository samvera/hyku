# frozen_string_literal: true
# Set nested indexer to graph by default. Remove after Hyrax 4.0 upgrade
ENV['HYRAX_USE_SOLR_GRAPH_NESTING'].present? || ENV['HYRAX_USE_SOLR_GRAPH_NESTING'] = "true"

# rubocop:disable Metrics/BlockLength
Hyrax.config do |config|
  # NOTE: We do not want to resgister the new resources as the lazy migration approach accounts for
  # that.  Were we to register generic_work_resource and generic_work, given Hyrax's implementation
  # we would see the duplicated option to create a generic work and a generic work.  The magic of
  # what we create/operate on is defined in the controller.
  #
  # See for details on how we generate routes from registered curation concern:
  #   https://github.com/samvera/hyrax/blob/main/lib/hyrax/rails/routes.rb
  #
  # See Hyrax::ValkyrieLazyMigration for details of how we make GenericWork and GenericWorkResource
  #     quack the same.
  config.register_curation_concern :generic_work
  config.register_curation_concern :image
  config.register_curation_concern :etd
  config.register_curation_concern :oer

  # Identify the model class name that will be used for Collections in your app
  # (i.e. ::Collection for ActiveFedora, Hyrax::PcdmCollection for Valkyrie)
  # config.collection_model = '::Collection'
  # Injected via `rails g hyrax:collection_resource CollectionResource`
  config.collection_model = 'CollectionResource'

  # Identify the model class name that will be used for Admin Sets in your app
  # (i.e. AdminSet for ActiveFedora, Hyrax::AdministrativeSet for Valkyrie)
  # config.admin_set_model = 'AdminSet'
  config.admin_set_model = 'AdminSetResource'

  # Identify the model class name that will be used for FileSets in your app
  #
  # TODO: We may need to add similar model_name overrides so that parameters and
  # keys are the same for FileSet and Hyrax::FileSet.  We do this for
  # GenericWorkResoure via Hyrax::ValkyrieLazyMigration.migrating(self, from:
  # GenericWork).  That may or may not work for FileSet but does provide the
  # breadcrumbs.
  config.file_set_model = 'Hyrax::FileSet'

  # The default method used for Solr queries. Values are :get or :post.
  # Post is suggested to prevent issues with URL length.
  config.solr_default_method = :post

  # The email address that messages submitted via the contact page are sent to
  # This is set by account settings
  # config.contact_email = 'changeme@example.com'

  # Text prefacing the subject entered in the contact form
  # config.subject_prefix = "Contact form:"

  # How many notifications should be displayed on the dashboard
  # config.max_notifications_for_dashboard = 5

  # How frequently should a file be audited.
  # config.max_days_between_fixity_checks = 7

  # Enable displaying usage statistics in the UI
  # Defaults to FALSE
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  # This is set by account settings
  # config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics
  # This is set by account settings

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Enables a link to the citations page for a generic_file.
  # Default is false
  # config.citations = false

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Specify the form of hostpath to be used in Endnote exports
  # config.persistent_hostpath = 'http://localhost/files/'

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  config.enable_ffmpeg = true

  # Using the database noid minter was too slow when ingesting 1000s of objects (8s per transaction),
  # so switching to UUIDs for the MVP.
  config.enable_noids = false

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Store identifier minter's state in a file for later replayability
  # config.minter_statefile = '/tmp/minter-state'

  # Specify the prefix for Redis keys:
  # Note this is only the default namespace for the proritor section. Tenants get their own namespace
  config.redis_namespace = ENV.fetch('HYRAX_REDIS_NAMESPACE', 'hyrax')

  # Specify the path to the file characterization tool:
  config.fits_path = ENV.fetch('HYRAX_FITS_PATH', '/app/fits/fits.sh')

  # Specify the path to the file derivatives creation tool:
  config.libreoffice_path = ENV.fetch('HYRAX_LIBREOFFICE_PATH', 'soffice')

  # Stream realtime notifications to users in the browser
  # config.realtime_notifications = true

  # Which RDF term should be used to relate objects to an admin set?
  # If this is a new repository, you may want to set a custom predicate term here to
  # avoid clashes if you plan to use the default (dct:isPartOf) for other relations.
  # config.admin_set_predicate = ::RDF::DC.isPartOf

  # Specify how many seconds back from the current time that we should show by default of the user's activity on the user's dashboard
  # config.activity_to_show_default_seconds_since_now = 24*60*60

  # Hyrax can integrate with Zotero's Arkivo service for automatic deposit
  # of Zotero-managed research items.
  # config.arkivo_api = false

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Location autocomplete uses geonames to search for named regions.
  # Specify the user for connecting to geonames:
  # This is set in account settings
  # config.geonames_username = ''

  # Should the acceptance of the licence agreement be active (checkbox), or
  # implied when the save button is pressed? Set to true for active.
  # The default is true.
  # config.active_deposit_agreement_acceptance = true

  # Should work creation require file upload, or can a work be created first
  # and a file added at a later time?
  # The default is true.
  config.work_requires_files = false

  # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
  # config.display_share_button_when_not_logged_in = true

  # The user who runs batch jobs. Update this if you aren't using emails
  # config.batch_user_key = 'batchuser@example.com'

  # The user who runs audit jobs. Update this if you aren't using emails
  # config.audit_user_key = 'audituser@example.com'
  #
  # The banner image. Should be 5000px wide by 1000px tall.
  # config.banner_image = 'https://cloud.githubusercontent.com/assets/92044/18370978/88ecac20-75f6-11e6-8399-6536640ef695.jpg'

  # Temporary path to hold uploads before they are ingested into FCrepo.
  # This must be a lambda that returns a Pathname
  config.upload_path = lambda {
    if Site.account&.s3_bucket.present?
      # For S3, no need to create directories
      "uploads/#{Apartment::Tenant.current}"
    else
      # Determine the base upload path
      base_path = if ENV['HYRAX_UPLOAD_PATH'].present?
                    Pathname.new(File.join(ENV['HYRAX_UPLOAD_PATH'], Apartment::Tenant.current))
                  else
                    Rails.root.join('public', 'uploads', Apartment::Tenant.current)
                  end

      # Create the directory if it doesn't exist
      FileUtils.mkdir_p(base_path) unless Dir.exist?(base_path)

      # Return the path
      base_path
    end
  }

  # Location on local file system where derivatives will be stored.
  # If you use a multi-server architecture, this MUST be a shared volume.
  config.derivatives_path = ENV['HYRAX_DERIVATIVES_PATH'].presence || Rails.root.join('tmp', 'derivatives').to_s

  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  # What default microdata type should be used if a more appropriate
  # type can not be found in the locale file?
  # config.microdata_default_type = 'http://schema.org/CreativeWork'

  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  # config.working_path = File.join(Rails.root, 'tmp', 'uploads')

  # Specify whether the media display partial should render a download link
  # config.display_media_download_link = true

  # Options to control the file uploader
  # Max size is set in accountsettings
  config.uploader = {
    limitConcurrentUploads: 6,
    maxNumberOfFiles: 100,
    maxFileSize: 5.gigabytes
  }

  # Fedora import/export tool
  #
  # Path to the Fedora import export tool jar file
  # config.import_export_jar_file_path = "tmp/fcrepo-import-export.jar"
  #
  # Location where Fedora object bags should be exported
  # config.bagit_directory = "tmp/exports"

  # If browse-everything has been configured, load the configs.  Otherwise, set to nil.
  # TODO: Re-enable this when work on BE has been prioritized
  # begin
  #   if defined? BrowseEverything
  #     config.browse_everything = BrowseEverything.config
  #   else
  #     Rails.logger.warn "BrowseEverything is not installed"
  #   end
  # rescue Errno::ENOENT
  #   config.browse_everything = nil
  # end
  config.browse_everything = nil

  config.iiif_image_server = true

  config.iiif_image_url_builder = lambda do |file_id, base_url, size, _format|
    # Comment this next line to allow universal viewer to work in development
    # Issue with Hyrax v 2.9.0 where IIIF has mixed content error when running with SSL enabled
    # See Samvera Slack thread https://samvera.slack.com/archives/C0F9JQJDQ/p1596718417351200?thread_ts=1596717896.350700&cid=C0F9JQJDQ
    base_url = base_url.sub(/\Ahttp:/, 'https:')
    Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size:)
  end

  config.iiif_info_url_builder = lambda do |file_id, base_url|
    uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)
    uri = uri.sub(%r{/info\.json\Z}, '')
    # Comment this next line to allow universal viewer to work in development
    # Issue with Hyrax v 2.9.0 where IIIF has mixed content error when running with SSL enabled
    # See Samvera Slack thread https://samvera.slack.com/archives/C0F9JQJDQ/p1596718417351200?thread_ts=1596717896.350700&cid=C0F9JQJDQ
    uri.sub(/\Ahttp:/, 'https:')
  end

  ##
  # A Valkyrie::Identifier is not a string but can be cast to a string.  What we have here is in
  # essence a "super" method.
  original_translator = config.translate_id_to_uri
  config.translate_id_to_uri = ->(id) { original_translator.call(id.to_s) }
end
# rubocop:enable Metrics/BlockLength

Date::DATE_FORMATS[:standard] = "%m/%d/%Y"

# Dynamically register file-based authorities from the `config/authorities` directory
begin
  # The Qa::Authorities::Local.names method will return all the .yml files in your
  # `config/authorities` directory. This will register each of them as a FileBasedAuthority
  if Qa::Authorities::Local.subauthorities_path
    Array.wrap(Qa::Authorities::Local.subauthorities_path).each do |path|
      next unless Dir.exist?(path)

      Qa::Authorities::Local.names.each do |subauth|
        Qa::Authorities::Local.register_subauthority(subauth, 'Qa::Authorities::Local::FileBasedAuthority')
      end
    end
  end
rescue Qa::ConfigDirectoryNotFound => e
  Rails.logger.warn("Hyrax config unable to find qa local authorities directory: #{e.message}")
rescue NameError => e
  Rails.logger.debug("Unexpected error during Hyrax configuration: #{e.message}")
end

# Register custom MeSH authority
Qa::Authorities::Local.register_subauthority('mesh', 'Qa::Authorities::Mesh')

Rails.application.config.to_prepare do
  Hyrax.config.file_set_indexer = Hyku::Indexers::FileSetIndexer

  # NOTE: Remote authorities like LOC don't need explicit registration
  # They are available by default through the QA engine routes

  Hyrax::IiifAv.config.iiif_av_viewer = :universal_viewer

  require 'hydra/derivatives'
  Hydra::Derivatives::Processors::Video::Processor.config.video_bitrate = '1500k'

  Hyrax.publisher.subscribe(HyraxListener.new)

  Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::IiifAv::IiifFileSetPresenter
  Hyrax::PcdmMemberPresenterFactory.file_presenter_class = Hyrax::IiifAv::IiifFileSetPresenter

  Hyrax::Transactions::Container.namespace('collection_resource') do |ops|
    ops.register 'save_collection_thumbnail', Hyrax::Transactions::Steps::SaveCollectionThumbnail.new
  end

  Hyrax::Resource.delegate(
    :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date, to: :embargo, allow_nil: true
  )

  Hyrax::Resource.delegate(
    :visibility_during_lease, :visibility_after_lease, :lease_expiration_date, to: :lease, allow_nil: true
  )
end
