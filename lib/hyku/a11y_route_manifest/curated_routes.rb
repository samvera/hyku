# frozen_string_literal: true

require "erb"

module Hyku
  module A11yRouteManifest
    # Curated tenant catalog/collection/work paths for the a11y manifest (keeps main module small for RuboCop).
    module CuratedRoutes
      module_function

      def tenant_public_paths(ctx)
        add = path_dedupe_collector
        add_tenant_public_catalog_paths(ctx, add)
        add_tenant_public_collection_paths(ctx, add)
        add_tenant_public_work_paths(ctx, add)
        add.paths
      end

      def path_dedupe_collector
        seen = {}
        out = []
        add = lambda do |p|
          next if p.blank?

          out << p unless seen[p]
          seen[p] = true
        end
        Struct.new(:add, :paths).new(add, out)
      end

      def add_tenant_public_catalog_paths(ctx, collector)
        app = ctx.app
        hyrax = ctx.hyrax
        add = collector.add
        add.call A11yRouteManifest.safe_path { app.root_path(locale: A11yRouteManifest::LOCALE) }
        add.call A11yRouteManifest.safe_path { app.search_catalog_path(locale: A11yRouteManifest::LOCALE) }
        add.call A11yRouteManifest.safe_path { app.advanced_search_catalog_path(locale: A11yRouteManifest::LOCALE) }
        add.call A11yRouteManifest.safe_path { app.all_collections_path(locale: A11yRouteManifest::LOCALE) }
        add.call A11yRouteManifest.safe_path { app.new_user_session_path(locale: A11yRouteManifest::LOCALE) }
        A11yRouteManifest::HYRAX_CONTENT_HELPERS.each do |meth|
          add.call A11yRouteManifest.safe_path { hyrax.public_send(meth, locale: A11yRouteManifest::LOCALE) }
        end
      end

      def add_tenant_public_collection_paths(ctx, collector)
        hyrax = ctx.hyrax
        cid = ctx.collection.id.to_s
        add = collector.add
        add.call A11yRouteManifest.safe_path { hyrax.collection_path(cid, locale: A11yRouteManifest::LOCALE) }
        return unless ctx.sub_collection

        add.call(
          A11yRouteManifest.safe_path do
            hyrax.collection_path(ctx.sub_collection.id.to_s, locale: A11yRouteManifest::LOCALE)
          end
        )
      end

      def add_tenant_public_work_paths(ctx, collector)
        hyrax = ctx.hyrax
        add = collector.add
        ctx.works.each do |w|
          wid = w.id.to_s
          add.call A11yRouteManifest.safe_path { ctx.app.solr_document_path(wid, locale: A11yRouteManifest::LOCALE) }
          add.call work_concern_show_path(hyrax, w)
          file_set_show_paths(w).each { |p| add.call p }
        end
      end

      def tenant_authenticated_paths(ctx)
        hyrax = ctx.hyrax
        seen = {}
        out = []
        add = lambda do |p|
          next if p.blank?

          out << p unless seen[p]
          seen[p] = true
        end

        add.call A11yRouteManifest.safe_path { hyrax.dashboard_path(locale: A11yRouteManifest::LOCALE) }
        add.call "/dashboard/works?locale=#{A11yRouteManifest::LOCALE}"
        add.call "/dashboard/collections?locale=#{A11yRouteManifest::LOCALE}"
        add.call A11yRouteManifest.safe_path { hyrax.admin_appearance_path(locale: A11yRouteManifest::LOCALE) }

        out
      end

      def work_concern_show_path(hyrax, work)
        route_key = work.class.model_name.singular_route_key
        meth = :"#{route_key}_path"
        return nil unless hyrax.respond_to?(meth)

        A11yRouteManifest.safe_path { hyrax.public_send(meth, work.id.to_s, locale: A11yRouteManifest::LOCALE) }
      end

      def file_set_show_paths(work)
        ids = Array(work.try(:member_ids))
        return [] if ids.blank?

        wid = ERB::Util.url_encode(work.id.to_s)
        ids.filter_map do |fs_id|
          next if fs_id.blank?

          "/concern/parent/#{wid}/file_sets/#{ERB::Util.url_encode(fs_id.to_s)}?locale=#{A11yRouteManifest::LOCALE}"
        end
      end
    end
  end
end
