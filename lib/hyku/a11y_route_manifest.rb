# frozen_string_literal: true

require "erb"
require "uri"

module Hyku
  # Builds Playwright manifest entries: { host, path } for HTML GET surfaces.
  # We cannot mirror every line of `rake routes` (POST-only, JSON APIs, missing params);
  # this merges high-value curated URLs with optional discoverable named GET routes.
  module A11yRouteManifest
    LOCALE = "en"
    # Extra GET routes beyond the curated list (0 = curated only). Discovery brute-forces path helpers
    # with seeded work/collection ids and can produce invalid URLs for unrelated :id params — default off.
    MAX_DISCOVERED = ENV.fetch("HYKU_A11Y_MANIFEST_DISCOVERY_MAX", "0").to_i

    HYRAX_CONTENT_HELPERS = %i[help_path about_path zotero_path mendeley_path terms_path].freeze

    # Named routes we should not probe (framework, non-HTML, auth handshakes, binaries).
    ROUTE_NAME_SKIP = %r{\A(rails_|action_|active_storage|mailbox|letter_opener)|(omniauth|passthru|callback)|(sidekiq|good_job)|_blob|_disk|_representation|api_sushi|webhooks}i

    PATH_PREFIX_SKIP = %w[
      /api/
      /rails/
      /images/
      /authorities/
      /browse
      /sword
      /jobs
      /status
    ].freeze

    Context = Struct.new(
      :app, :hyrax, :admin_host, :tenant_host, :collection, :work, :works, :sub_collection,
      keyword_init: true
    )

    module_function

    def build(admin_host:, tenant_host:, collection:, work:, works: nil, sub_collection: nil)
      works_list = normalize_works_list(work, works)
      ctx = Context.new(
        app: Rails.application.routes.url_helpers,
        hyrax: Hyrax::Engine.routes.url_helpers,
        admin_host: admin_host,
        tenant_host: tenant_host,
        collection: collection,
        work: work,
        works: works_list,
        sub_collection: sub_collection
      )
      public_routes = curated_admin_routes(ctx) + curated_public_tenant_routes(ctx) + Discovery.routes(ctx)
      authenticated = curated_authenticated_tenant_routes(ctx)
      {
        routes: dedupe(public_routes),
        authenticated_routes: dedupe(authenticated)
      }
    end

    def normalize_works_list(primary, extras)
      list = Array(extras).compact
      list = [primary] if list.empty?
      list.unshift(primary) unless list.any? { |w| w.id == primary.id }
      list.uniq(&:id)
    end

    def curated_admin_routes(ctx)
      out = [{ host: ctx.admin_host, path: "/" }]
      if multitenant? && ctx.app.respond_to?(:new_sign_up_path)
        p = safe_path { ctx.app.new_sign_up_path(locale: LOCALE) } || safe_path { ctx.app.new_sign_up_path }
        out << { host: ctx.admin_host, path: p } if p.present?
      end
      out
    end

    def curated_public_tenant_routes(ctx)
      paths = tenant_public_paths(ctx)
      paths.compact.map { |p| { host: ctx.tenant_host, path: p } }
    end

    # Hyrax dashboard + admin UI (requires tenant admin session in Playwright).
    def curated_authenticated_tenant_routes(ctx)
      paths = tenant_authenticated_paths(ctx)
      paths.compact.map { |p| { host: ctx.tenant_host, path: p } }
    end

    def tenant_public_paths(ctx)
      app = ctx.app
      hyrax = ctx.hyrax
      cid = ctx.collection.id.to_s
      seen = {}
      out = []
      add = lambda do |p|
        next if p.blank?

        out << p unless seen[p]
        seen[p] = true
      end

      add.call safe_path { app.root_path(locale: LOCALE) }
      add.call safe_path { app.search_catalog_path(locale: LOCALE) }
      add.call safe_path { app.advanced_search_catalog_path(locale: LOCALE) }
      add.call safe_path { app.all_collections_path(locale: LOCALE) }
      add.call safe_path { app.new_user_session_path(locale: LOCALE) }
      HYRAX_CONTENT_HELPERS.each { |meth| add.call safe_path { hyrax.public_send(meth, locale: LOCALE) } }
      add.call safe_path { hyrax.collection_path(cid, locale: LOCALE) }
      add.call safe_path { hyrax.collection_path(ctx.sub_collection.id.to_s, locale: LOCALE) } if ctx.sub_collection

      ctx.works.each do |w|
        wid = w.id.to_s
        add.call safe_path { app.solr_document_path(wid, locale: LOCALE) }
        add.call work_concern_show_path(hyrax, w)
        file_set_show_paths(w).each { |p| add.call p }
      end

      out
    end

    def tenant_authenticated_paths(ctx)
      hyrax = ctx.hyrax
      app = ctx.app
      seen = {}
      out = []
      add = lambda do |p|
        next if p.blank?

        out << p unless seen[p]
        seen[p] = true
      end

      add.call safe_path { hyrax.dashboard_path(locale: LOCALE) }
      add.call "/dashboard/works?locale=#{LOCALE}"
      add.call "/dashboard/collections?locale=#{LOCALE}"
      add.call safe_path { hyrax.admin_appearance_path(locale: LOCALE) }

      out
    end

    def work_concern_show_path(hyrax, work)
      route_key = work.class.model_name.singular_route_key
      meth = :"#{route_key}_path"
      return nil unless hyrax.respond_to?(meth)

      safe_path { hyrax.public_send(meth, work.id.to_s, locale: LOCALE) }
    end

    # Hyrax HTML file set show: nested under parent work (see work item filename links).
    def file_set_show_paths(work)
      ids = Array(work.try(:member_ids))
      return [] if ids.blank?

      wid = ERB::Util.url_encode(work.id.to_s)
      ids.filter_map do |fs_id|
        next if fs_id.blank?

        "/concern/parent/#{wid}/file_sets/#{ERB::Util.url_encode(fs_id.to_s)}?locale=#{LOCALE}"
      end
    end

    def dedupe(routes)
      out = []
      seen = {}
      routes.each do |r|
        key = [r[:host], r[:path]]
        next if seen[key]
        seen[key] = true
        out << r
      end
      out
    end

    def multitenant?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("HYKU_MULTITENANT", false))
    end

    def safe_path
      yield
    rescue ActionController::UrlGenerationError, ArgumentError, NoMethodError, TypeError
      nil
    end

    # Introspects named GET routes from the app and Hyrax; generates paths using seeded work/collection IDs.
    module Discovery
      module_function

      def routes(ctx)
        return [] if MAX_DISCOVERED <= 0

        names = named_get_route_names([Rails.application.routes, Hyrax::Engine.routes])
        seen_paths = {}
        out = []

        names.each do |name|
          break if out.size >= MAX_DISCOVERED
          next if ROUTE_NAME_SKIP.match?(name.to_s)

          path = path_for_named_route(ctx.app, ctx.hyrax, name, ctx.collection, ctx.work)
          next unless path
          next unless acceptable_discovered_path?(path)

          host = host_for_discovered_path(path, ctx.admin_host, ctx.tenant_host)
          key = [host, path]
          next if seen_paths[key]
          seen_paths[key] = true
          out << { host: host, path: path }
        end

        out
      end

      def named_get_route_names(route_sets)
        names = []
        route_sets.each do |set|
          set.routes.each do |route|
            next if route.internal
            next unless route.name
            next unless route.verb == "GET"

            names << route.name.to_sym
          end
        end
        names.uniq.sort
      end

      def path_for_named_route(app, hyrax, name, collection, work)
        [app, hyrax].each do |helpers|
          path = try_named_path(helpers, name, collection, work)
          return path if path
        end
        nil
      end

      def try_named_path(helpers, name, collection, work)
        meth = :"#{name}_path"
        return nil unless helpers.respond_to?(meth)

        each_named_path_attempt(helpers, meth, collection, work) do |raw|
          p = normalize_path(raw)
          return p if p.present?
        end
        nil
      end

      def each_named_path_attempt(helpers, meth, collection, work)
        wid = work.id.to_s
        cid = collection.id.to_s
        [
          -> { helpers.public_send(meth, locale: LOCALE) },
          -> { helpers.public_send(meth) },
          -> { helpers.public_send(meth, wid, locale: LOCALE) },
          -> { helpers.public_send(meth, id: wid, locale: LOCALE) },
          -> { helpers.public_send(meth, cid, locale: LOCALE) },
          -> { helpers.public_send(meth, id: cid, locale: LOCALE) },
          -> { helpers.public_send(meth, format: :html, locale: LOCALE) }
        ].each do |pr|
          raw = pr.call
          yield raw
        rescue ActionController::UrlGenerationError, ArgumentError, TypeError, NoMethodError, URI::InvalidURIError
          next
        end
      end

      def host_for_discovered_path(path, admin_host, tenant_host)
        return tenant_host unless A11yRouteManifest.multitenant?

        uri_path = path.split("?", 2).first
        return admin_host if uri_path == "/account/sign_up" || uri_path.start_with?("/proprietor/")

        tenant_host
      end

      def acceptable_discovered_path?(path)
        uri_path = path.split("?", 2).first
        return false if uri_path.blank?
        return false if uri_path.match?(%r{/[:\*]})
        return false if PATH_PREFIX_SKIP.any? { |pre| uri_path.start_with?(pre) }
        return false if /\.(json|xml|rss|ttl)\z/i.match?(uri_path)

        true
      end

      def normalize_path(candidate)
        return nil if candidate.blank?
        str = candidate.to_s
        if str.start_with?("http://", "https://")
          uri = URI.parse(str)
          str = uri.path.to_s
          str = "#{str}?#{uri.query}" if uri.query.present?
        end
        return nil if str.blank?

        str
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
