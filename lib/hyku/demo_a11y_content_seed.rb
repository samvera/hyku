# frozen_string_literal: true

require "json"
require "fileutils"
require "pathname"

require_relative "a11y_route_manifest"

module Hyku
  # Idempotent test data + manifest for Playwright WCAG route audits (Docker / CI).
  # See rake hyku:demo_content:seed and docs/accessibility/README.md.
  class DemoA11yContentSeed
    COLLECTION_TITLE = "Hyku A11y Demo Collection"
    WORK_TITLE = "Hyku A11y Demo Work"
    DEMO_IMAGE_TITLE = "Hyku A11y Demo Image"
    DEMO_ETD_TITLE = "Hyku A11y Demo ETD"
    DEMO_OER_TITLE = "Hyku A11y Demo OER"
    DEMO_AUDIO_WORK_TITLE = "Hyku A11y Demo Work — Audio"
    DEMO_SUB_COLLECTION_TITLE = "Hyku A11y Demo Sub-Collection"
    DEMO_NESTED_WORK_TITLE = "Hyku A11y Demo Nested Work"
    # Nested branch: one work type + attachment (file must exist under db/seeds/sample; already required for top-level Image work).
    DEMO_NESTED_WORK_CLASS = ImageResource
    DEMO_NESTED_WORK_FILES = %w[landscape_hires_4000x2667_6.83mb.jpg].freeze
    DEMO_DEPOSITOR_EMAIL = "hyku-a11y-demo-depositor@example.com"
    # Tenant admin for Playwright dashboard audits (not INITIAL_ADMIN / admin@example.com).
    DEMO_A11Y_ADMIN_EMAIL = "hyku-a11y-admin@example.com"

    # Binaries expected under db/seeds/sample (same set as Sample::ValkyrieService).
    DEMO_SAMPLE_FILE_CANDIDATES = %w[
      sample-report.pdf
      landscape_hires_4000x2667_6.83mb.jpg
      mp3_44100Hz_128kbps_stereo.mp3
      m4a_48000Hz_256kbps_stereo.m4a
      big_buck_bunny_720p_10mb.mp4
    ].freeze

    # One demo work per type where it fits; PDF is reused for generic + ETD; both audio files on one generic work.
    DEMO_WORK_SEED_SPECS = [
      { klass: GenericWorkResource, title: WORK_TITLE, files: %w[sample-report.pdf] },
      { klass: ImageResource, title: DEMO_IMAGE_TITLE, files: %w[landscape_hires_4000x2667_6.83mb.jpg] },
      { klass: EtdResource, title: DEMO_ETD_TITLE, files: %w[sample-report.pdf] },
      { klass: OerResource, title: DEMO_OER_TITLE, files: %w[big_buck_bunny_720p_10mb.mp4] },
      { klass: GenericWorkResource, title: DEMO_AUDIO_WORK_TITLE,
        files: %w[mp3_44100Hz_128kbps_stereo.mp3 m4a_48000Hz_256kbps_stereo.m4a] }
    ].freeze

    # Subdomain piece; full host follows HYKU_DEFAULT_HOST (e.g. a11y-demo-hyku.localhost.direct for Docker + Traefik).
    DEMO_ACCOUNT_TENANT_SLUG = "a11y-demo"

    class << self
      def run!(manifest_path: Rails.root.join("e2e", "a11y-routes", "a11y-routes.manifest.json"))
        unless allowed_to_run?
          raise <<~MSG.squish
            hyku:demo_content:seed may only run in RAILS_ENV=test (e.g. `RAILS_ENV=test bundle exec rake hyku:demo_content:seed`),
            or in development when HYKU_DEMO_A11Y_SEED=1 or IN_DOCKER=true (docker compose sets IN_DOCKER in .env).
          MSG
        end

        new(manifest_path: manifest_path).run
      end

      def allowed_to_run?
        return true if Rails.env.test?
        return false unless Rails.env.development?

        ENV["HYKU_DEMO_A11Y_SEED"] == "1" ||
          ActiveModel::Type::Boolean.new.cast(ENV.fetch("IN_DOCKER", false))
      end
    end

    def initialize(manifest_path:)
      @manifest_path = manifest_path
    end

    def run
      assert_accounts_schema_for_create_account!
      switch_to_public_schema!
      account = ensure_demo_account!
      Apartment::Tenant.switch!(account.tenant)
      account.reload.switch!
      ensure_demo_site_account!(account)
      ensure_site_available_works!
      ensure_demo_a11y_admin!
      ensure_demo_depositor_is_tenant_admin!
      collection, primary_work = ensure_repository_objects!
      index_solr!(collection, account: account)
      write_manifest!(account, collection, primary_work)
      puts "hyku:demo_content:seed wrote #{@manifest_path}"
    end

    private

    def switch_to_public_schema!
      Apartment::Tenant.switch!(Apartment.default_tenant)
    end

    def assert_accounts_schema_for_create_account!
      unless Account.connection.data_source_exists?(Account.table_name)
        raise <<~MSG.squish
          hyku:demo_content:seed requires a migrated database (table #{Account.table_name} is missing).
          Run `RAILS_ENV=#{Rails.env} bundle exec rails db:prepare` (or db:migrate), then retry.
          ./bin/playwright-a11y runs db:prepare automatically before the seed.
        MSG
      end

      required = %w[data_cite_endpoint_id solr_endpoint_id fcrepo_endpoint_id redis_endpoint_id]
      missing = required.reject { |col| Account.column_names.include?(col) }
      return if missing.empty?

      raise <<~MSG.squish
        hyku:demo_content:seed requires accounts columns #{missing.join(', ')}.
        Your database schema is out of date — run `rails db:migrate` or reload from db/schema.rb
        (e.g. db:drop db:create db:schema:load) so CreateAccount / CreateAccountInlineJob can run.
      MSG
    end

    def demo_cname
      return Account.canonical_cname(ENV["HYKU_A11Y_DEMO_CNAME"]) if ENV["HYKU_A11Y_DEMO_CNAME"].present?

      slug = DEMO_ACCOUNT_TENANT_SLUG.parameterize
      template = ENV["HYKU_DEFAULT_HOST"].presence ||
                 "%{tenant}-#{ENV.fetch('APP_NAME', 'hyku')}.localhost.direct"
      Account.canonical_cname(format(template, tenant: slug))
    end

    def ensure_demo_account!
      existing = Account.from_cname(demo_cname)
      return existing if existing&.persisted?

      account = Account.new(name: "Hyku A11y Demo #{demo_cname}")
      account.domain_names.build(cname: demo_cname, is_active: true)
      creator = CreateAccount.new(account)
      raise "CreateAccount failed: #{account.errors.full_messages.presence || 'unknown'}" unless creator.save

      account.reload
    end

    def ensure_site_available_works!
      site = Site.instance
      return if site.available_works.present?

      site.available_works = Hyrax.config.registered_curation_concern_types
      site.save!
    end

    # CreateAccount links Site → Account inside Apartment::Tenant.create; older tenants or restored DBs
    # may omit this. Indexers and Solr stale-doc purge use Site.instance.account.cname — without it,
    # purge is skipped and Solr keeps dead collection/work ids (manifest vs catalog links 404 in Valkyrie).
    def ensure_demo_site_account!(account)
      site = Site.instance
      return unless site.is_a?(Site)

      return if site.account_id == account.id

      site.update!(account: account)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
      Rails.logger.warn("[hyku:demo_content:seed] Site#account could not be set: #{e.message}")
    end

    def tenant_solr_cname(account)
      Site.instance&.account&.cname.presence ||
        account.domain_names.where(is_active: true).pick(:cname).presence ||
        demo_cname
    end

    def demo_resource_title_match?(resource, expected_title)
      Array.wrap(resource.title).map(&:to_s) == [expected_title.to_s]
    end

    def find_demo_collection
      Hyrax.query_service.find_all_of_model(model: Hyrax.config.collection_class).find do |c|
        demo_resource_title_match?(c, COLLECTION_TITLE)
      end
    end

    def find_demo_work(klass, title)
      Hyrax.query_service.find_all_of_model(model: klass).find do |w|
        demo_resource_title_match?(w, title)
      end
    end

    def demo_depositor_password
      ENV.fetch("HYKU_DEMO_DEPOSITOR_PASSWORD") do
        ENV.fetch("HYKU_USER_DEFAULT_PASSWORD", "password")
      end
    end

    def demo_a11y_admin_password
      ENV.fetch("HYKU_DEMO_A11Y_ADMIN_PASSWORD") do
        ENV.fetch("HYKU_USER_DEFAULT_PASSWORD", "password")
      end
    end

    # Full dashboard Ability (mirrors db/seeds.rb INITIAL_ADMIN block for this tenant).
    def ensure_demo_a11y_admin!
      pwd = demo_a11y_admin_password
      user = User.find_or_initialize_by(email: DEMO_A11Y_ADMIN_EMAIL)
      user.password = pwd
      user.password_confirmation = pwd
      user.save!
      user.add_default_group_membership!
      user.add_role(:admin, Site.instance) unless user.has_role?(:admin, Site.instance)
      Hyrax::Group.find_or_create_by!(name: Ability.admin_group_name).add_members_by_id(user.id)
      user
    end

    def ensure_demo_depositor_user
      @ensure_demo_depositor_user ||= User.find_by(email: DEMO_DEPOSITOR_EMAIL) || User.create!(
        email: DEMO_DEPOSITOR_EMAIL,
        password: demo_depositor_password,
        password_confirmation: demo_depositor_password
      )
    end

    def ensure_demo_depositor_is_tenant_admin!
      user = ensure_demo_depositor_user
      return if user.has_role?(:admin, Site.instance)

      user.add_role(:admin, Site.instance)
    end

    def ensure_demo_work_is_public!(work)
      return if work.permission_manager.read_groups.to_a.include?("public")

      Hyrax::VisibilityWriter.new(resource: work).assign_access_for(
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      )
      work.permission_manager.acl.save
    end

    def ensure_demo_collection_is_public!(collection)
      return if collection.permission_manager.read_groups.to_a.include?("public")

      Hyrax::VisibilityWriter.new(resource: collection).assign_access_for(
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      )
      collection.permission_manager.acl.save
    end

    def demo_work_seed_extra_attributes(klass)
      case klass.name
      when "EtdResource"
        {
          keyword: ["accessibility", "demo"],
          rights_statement: ["http://rightsstatements.org/vocab/InC/1.0/"],
          date: [Time.zone.today.year.to_s],
          degree_name: ["Doctor of Philosophy"],
          degree_level: ["Doctoral"],
          degree_discipline: ["Library Science"],
          degree_grantor: ["Demo University"],
          resource_type: ["Dissertation"]
        }
      when "OerResource"
        {
          resource_type: ["InteractiveResource"],
          date_created: [Time.zone.today.strftime("%Y-%m-%d")],
          audience: ["Educator"],
          education_level: ["Higher Education"],
          learning_resource_type: ["Demonstration"],
          discipline: ["Information Science"],
          rights_statement: ["http://rightsstatements.org/vocab/InC/1.0/"]
        }
      else
        {}
      end
    end

    def create_demo_collection!(user, title: COLLECTION_TITLE, member_of_collection_ids: [])
      collection_type = Hyrax::CollectionType.find_or_create_default_collection_type
      attrs = {
        title: [title],
        creator: ["Hyku A11y Demo"],
        collection_type_gid: collection_type.to_global_id.to_s,
        depositor: user.user_key,
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      }
      attrs[:member_of_collection_ids] = member_of_collection_ids if member_of_collection_ids.present?

      collection = Hyrax.config.collection_class.new(attrs)
      collection = Hyrax.persister.save(resource: collection)
      ensure_demo_collection_is_public!(collection)
      Sample::PermissionTemplateService.create_for_valkyrie_collection(collection, user)
      Hyrax.index_adapter.save(resource: collection)
      Hyrax.publisher.publish("collection.metadata.updated", collection: collection, user: user)
      collection
    end

    def find_demo_sub_collection(parent)
      pid = parent.id.to_s
      Hyrax.query_service.find_all_of_model(model: Hyrax.config.collection_class).find do |c|
        next false unless demo_resource_title_match?(c, DEMO_SUB_COLLECTION_TITLE)

        Array(c.member_of_collection_ids).map(&:to_s).include?(pid)
      end
    end

    def link_collection_to_parent!(child, parent)
      pid = parent.id.to_s
      ids = Array(child.member_of_collection_ids).map(&:to_s)
      return if ids.include?(pid)

      child.member_of_collection_ids = (Array(child.member_of_collection_ids) + [parent.id]).uniq
      Hyrax.persister.save(resource: child)
    end

    def ensure_nested_demo_branch!(dep, parent_collection)
      sub = find_demo_sub_collection(parent_collection) ||
            create_demo_collection!(dep, title: DEMO_SUB_COLLECTION_TITLE, member_of_collection_ids: [parent_collection.id])
      sub = Hyrax.query_service.find_by(id: sub.id)
      link_collection_to_parent!(sub, parent_collection)
      ensure_demo_collection_is_public!(sub)

      klass = DEMO_NESTED_WORK_CLASS
      nested = find_demo_work(klass, DEMO_NESTED_WORK_TITLE) ||
               create_demo_work!(dep, klass: klass, title: DEMO_NESTED_WORK_TITLE)
      link_work_to_collection!(nested, sub)
      ensure_demo_work_is_public!(nested)
      nested = Hyrax.query_service.find_by(id: nested.id)
      paths = DEMO_NESTED_WORK_FILES.map { |f| sample_files_dir.join(f) }
      attach_demo_sample_files!(nested, dep, paths)
      ensure_demo_work_is_public!(Hyrax.query_service.find_by(id: nested.id))
    end

    def create_demo_work!(user, klass:, title:)
      admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id
      attrs = {
        title: [title],
        creator: ["Hyku A11y Demo"],
        depositor: user.user_key,
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
        admin_set_id: admin_set_id
      }.merge(demo_work_seed_extra_attributes(klass))

      work = klass.new(attrs)
      work = Hyrax.persister.save(resource: work)
      Hyrax.index_adapter.save(resource: work)
      Hyrax.publisher.publish("object.deposited", object: work, user: user)
      Hyrax.publisher.publish("object.metadata.updated", object: work, user: user)
      work
    end

    def link_work_to_collection!(work, collection)
      cid = collection.id.to_s
      ids = Array(work.member_of_collection_ids).map(&:to_s)
      return if ids.include?(cid)

      work.member_of_collection_ids = (Array(work.member_of_collection_ids) + [collection.id]).uniq
      Hyrax.persister.save(resource: work)
    end

    def sample_files_dir
      Rails.root.join("db", "seeds", "sample")
    end

    def assert_demo_sample_media_present!
      required_files = (DEMO_WORK_SEED_SPECS.flat_map { |spec| spec[:files] } + DEMO_NESTED_WORK_FILES).uniq
      missing = required_files.filter_map do |name|
        path = sample_files_dir.join(name)
        next nil if path.file?

        "#{name} → #{path}"
      end
      return if missing.empty?

      raise <<~MSG.squish
        hyku:demo_content:seed needs these files under #{sample_files_dir}:
        #{missing.map { |m| "  - #{m}" }.join("\n")}
        Add the binaries (see Sample::ValkyrieService / rake db:seed:sample) or trim DEMO_WORK_SEED_SPECS.
      MSG
    end

    def demo_work_file_sets_with_original_count(work)
      original_use = Hyrax::FileMetadata::Use.uri_for(use: :original_file)
      Array(work.member_ids).count do |fs_id|
        fs = Hyrax.query_service.find_by(id: fs_id)
        next false unless fs.respond_to?(:file_ids)
        next false if fs.file_ids.blank?

        Hyrax.custom_queries.find_many_file_metadata_by_use(resource: fs, use: original_use).present?
      rescue Valkyrie::Persistence::ObjectNotFoundError
        false
      end
    end

    def demo_work_attachment_complete?(work, expected_file_sets)
      return false unless work.respond_to?(:member_ids) && work.member_ids.present?

      demo_work_file_sets_with_original_count(work) >= expected_file_sets
    end

    def attach_demo_sample_files!(work, user, paths)
      work = Hyrax.query_service.find_by(id: work.id)
      return if demo_work_attachment_complete?(work, paths.length)

      paths.each do |p|
        raise "hyku:demo_content:seed missing sample file: #{p}" unless p.file?
      end

      @demo_attach_original_use_valkyrie = Hyrax.config.use_valkyrie?
      @demo_attach_original_hyrax_queue = ENV["HYRAX_ACTIVE_JOB_QUEUE"]
      @demo_attach_original_queue_adapter = ActiveJob::Base.queue_adapter
      begin
        ENV["HYRAX_ACTIVE_JOB_QUEUE"] = "inline"
        ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::InlineAdapter.new
        ENV["HYRAX_VALKYRIE"] = "true"
        Hyrax.config.use_valkyrie = true

        uploaded_files = paths.map { |p| Hyrax::UploadedFile.create(file: File.open(p.to_s), user: user) }
        AttachFilesToWorkJob.perform_now(work, uploaded_files)

        work = Hyrax.query_service.find_by(id: work.id)
        Hyrax.persister.save(resource: work)
        Hyrax.index_adapter.save(resource: work)
        Array(work.member_ids).each do |fs_id|
          fs = Hyrax.query_service.find_by(id: fs_id)
          Hyrax.index_adapter.save(resource: fs) if fs
        end
      ensure
        Hyrax.config.use_valkyrie = @demo_attach_original_use_valkyrie
        ENV["HYRAX_VALKYRIE"] = @demo_attach_original_use_valkyrie.to_s
        ENV["HYRAX_ACTIVE_JOB_QUEUE"] = @demo_attach_original_hyrax_queue
        ActiveJob::Base.queue_adapter = @demo_attach_original_queue_adapter
      end
    end

    def ensure_repository_objects!
      dep = ensure_demo_depositor_user
      collection = find_demo_collection || create_demo_collection!(dep)
      collection = Hyrax.query_service.find_by(id: collection.id)
      ensure_demo_collection_is_public!(collection)
      assert_demo_sample_media_present!

      primary_work = nil

      DEMO_WORK_SEED_SPECS.each do |spec|
        work = find_demo_work(spec[:klass], spec[:title]) ||
               create_demo_work!(dep, klass: spec[:klass], title: spec[:title])
        primary_work ||= work if spec[:klass] == GenericWorkResource && spec[:title] == WORK_TITLE

        link_work_to_collection!(work, collection)
        ensure_demo_work_is_public!(work)
        work = Hyrax.query_service.find_by(id: work.id)
        paths = spec[:files].map { |f| sample_files_dir.join(f) }
        attach_demo_sample_files!(work, dep, paths)
        ensure_demo_work_is_public!(Hyrax.query_service.find_by(id: work.id))
      end

      ensure_nested_demo_branch!(dep, collection)

      collection = Hyrax.query_service.find_by(id: collection.id)
      ensure_demo_collection_is_public!(collection)
      raise "hyku:demo_content:seed could not resolve primary GenericWork for manifest" if primary_work.blank?

      primary_work = Hyrax.query_service.find_by(id: primary_work.id)
      [collection, primary_work]
    end

    def index_solr!(collection, account:)
      solr = Blacklight.default_index.connection
      purge_stale_demo_solr_docs!(solr, collection, account: account)
      solr.add(CollectionResourceIndexer.new(resource: collection).to_solr)
      DEMO_WORK_SEED_SPECS.each do |spec|
        w = find_demo_work(spec[:klass], spec[:title])
        next unless w

        w = Hyrax.query_service.find_by(id: w.id)
        solr.add(w.to_solr)
      end

      sub = find_demo_sub_collection(collection)
      if sub
        sub = Hyrax.query_service.find_by(id: sub.id)
        solr.add(CollectionResourceIndexer.new(resource: sub).to_solr)
      end

      nested = find_demo_work(DEMO_NESTED_WORK_CLASS, DEMO_NESTED_WORK_TITLE)
      if nested
        nested = Hyrax.query_service.find_by(id: nested.id)
        solr.add(nested.to_solr)
      end

      solr.commit
    end

    def purge_stale_demo_solr_docs!(solr, collection, account:)
      cname = tenant_solr_cname(account)
      return if cname.blank?

      delete_stale_solr_docs_for_demo_title!(solr, cname, COLLECTION_TITLE, collection.id.to_s)
      DEMO_WORK_SEED_SPECS.each do |spec|
        w = find_demo_work(spec[:klass], spec[:title])
        keep_id = w&.id&.to_s
        delete_stale_solr_docs_for_demo_title!(solr, cname, spec[:title], keep_id)
      end

      sub = find_demo_sub_collection(collection)
      delete_stale_solr_docs_for_demo_title!(solr, cname, DEMO_SUB_COLLECTION_TITLE, sub&.id&.to_s)

      nested = find_demo_work(DEMO_NESTED_WORK_CLASS, DEMO_NESTED_WORK_TITLE)
      delete_stale_solr_docs_for_demo_title!(solr, cname, DEMO_NESTED_WORK_TITLE, nested&.id&.to_s)
    rescue StandardError => e
      Rails.logger.warn("[hyku:demo_content:seed] Solr stale-doc purge skipped: #{e.message}")
    end

    def delete_stale_solr_docs_for_demo_title!(solr, cname, title, keep_id)
      q = %(account_cname_tesim:"#{escape_lucene_term(cname)}" AND title_tesim:"#{escape_lucene_term(title)}")
      docs = Hyrax::SolrService.query(q, fl: "id", rows: 100)
      stale_ids = Array(docs).map { |d| d.id.to_s }.compact
      stale_ids.reject! { |id| id == keep_id } if keep_id.present?
      stale_ids.each { |id| solr.delete_by_id(id) }
    end

    def escape_lucene_term(str)
      str.to_s.gsub('\\', '\\\\').gsub('"', '\\"')
    end

    def demo_works_for_manifest
      list = DEMO_WORK_SEED_SPECS.filter_map { |spec| find_demo_work(spec[:klass], spec[:title]) }
      nested = find_demo_work(DEMO_NESTED_WORK_CLASS, DEMO_NESTED_WORK_TITLE)
      list << nested if nested
      list
    end

    def write_manifest!(account, collection, work)
      tenant_host = account.domain_names.find_by(is_active: true)&.cname || demo_cname
      admin_host = ENV.fetch("HYKU_ADMIN_HOST", "admin-hyku.localhost.direct")
      port = ENV.fetch("PLAYWRIGHT_SERVER_PORT", "3000").to_i

      built = Hyku::A11yRouteManifest.build(
        admin_host: admin_host,
        tenant_host: tenant_host,
        collection: collection,
        work: work,
        works: demo_works_for_manifest,
        sub_collection: find_demo_sub_collection(collection)
      )

      payload = {
        tenant_cname: tenant_host,
        admin_host: admin_host,
        port: port,
        a11y_admin_email: DEMO_A11Y_ADMIN_EMAIL,
        a11y_admin_password_env: "HYKU_DEMO_A11Y_ADMIN_PASSWORD",
        routes: built[:routes],
        authenticated_routes: built[:authenticated_routes]
      }

      FileUtils.mkdir_p(File.dirname(@manifest_path))
      File.write(@manifest_path, JSON.pretty_generate(payload))
    end
  end
end
