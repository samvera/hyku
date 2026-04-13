# frozen_string_literal: true

require "uri"

require_relative "a11y_route_manifest/curated_routes"

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

    # +extras+ may include +:works+ (array) and +:sub_collection+ (optional) to satisfy Metrics/ParameterLists.
    def build(admin_host:, tenant_host:, collection:, work:, extras: {})
      works_list = normalize_works_list(work, extras[:works])
      sub_collection = extras[:sub_collection]
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
      CuratedRoutes.tenant_public_paths(ctx)
    end

    def tenant_authenticated_paths(ctx)
      CuratedRoutes.tenant_authenticated_paths(ctx)
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
  end
end

require_relative "a11y_route_manifest/discovery"
