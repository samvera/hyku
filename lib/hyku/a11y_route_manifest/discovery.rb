# frozen_string_literal: true

require "uri"

module Hyku
  module A11yRouteManifest
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
        method = :"#{name}_path"
        return nil unless helpers.respond_to?(method)

        each_named_path_attempt(helpers, method, collection, work) do |raw|
          p = normalize_path(raw)
          return p if p.present?
        end
        nil
      end

      def each_named_path_attempt(helpers, method, collection, work)
        wid = work.id.to_s
        cid = collection.id.to_s
        [
          -> { helpers.public_send(method, locale: LOCALE) },
          -> { helpers.public_send(method) },
          -> { helpers.public_send(method, wid, locale: LOCALE) },
          -> { helpers.public_send(method, id: wid, locale: LOCALE) },
          -> { helpers.public_send(method, cid, locale: LOCALE) },
          -> { helpers.public_send(method, id: cid, locale: LOCALE) },
          -> { helpers.public_send(method, format: :html, locale: LOCALE) }
        ].each do |pr|
          raw = pr.call
          yield raw
        rescue ActionController::UrlGenerationError, ArgumentError, TypeError, NomethododError, URI::InvalidURIError
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
