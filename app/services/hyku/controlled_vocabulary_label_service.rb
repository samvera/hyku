# frozen_string_literal: true

module Hyku
  # Hyrax discovers vocabularies through `Qa::Authorities::Local.subauthorities`,
  # which lists only the yaml files in config/authorities. Hyku's are created in
  # the dashboard and live in `qa_local_authorities` rows, so upstream answers
  # `resolvable? == false` for every one of them and their labels never resolve.
  #
  # Hyku is also multi-tenant, and two tenants routinely hold a vocabulary of the
  # same name with different terms. Upstream keys its cache on the name alone, so
  # a shared key would answer one tenant with another's labels.
  class ControlledVocabularyLabelService < Hyrax::QaControlledVocabularyLabelService
    # A database row counts as a vocabulary, and a remote authority never does:
    # resolving one means a network call per value, which has no place in an
    # indexing run.
    def resolvable?(source)
      name = source.to_s.strip
      return false if name.blank?
      return false if Hyrax::ControlledVocabularies.remote_authorities.key?(name)

      database_backed?(name) || super
    end

    # Apartment's :switch callback reaches this through Site.reset!, so the maps
    # built for the previous tenant are dropped before the next one reads them.
    def reset!
      RequestStore.store.except!(:hyku_controlled_vocabulary_label_maps,
                                 :hyku_controlled_vocabulary_names,
                                 :hyku_controlled_vocabulary_versions)
      @local_authority_names = nil
    end

    private

    def database_backed?(name)
      database_names.include?(name)
    end

    def database_names
      RequestStore.store[:hyku_controlled_vocabulary_names] ||= Qa::LocalAuthority.pluck(:name).to_set
    rescue ActiveRecord::StatementInvalid => e
      # No qa tables yet (early boot, a fresh database).
      Hyrax.logger.debug { "Unable to look up local authorities: #{e.message}" }
      Set.new
    end

    # Versioned by the authority's rows, not left to CACHE_EXPIRATION alone: a
    # timer-only key hands the indexer the labels as they stood before a term
    # edit, so a reindex run straight afterward writes stale labels into Solr.
    def cache_key(name)
      "#{super}-#{Apartment::Tenant.current}-#{terms_version(name)}"
    end

    # nil where no rows back the name, which leaves a yaml-only vocabulary keyed
    # as before -- its terms change only on deploy.
    def terms_version(name)
      terms_versions[name]
    end

    def terms_versions
      RequestStore.store[:hyku_controlled_vocabulary_versions] ||= begin
        counts = Qa::LocalAuthorityEntry.group(:local_authority_id).count
        stamps = Qa::LocalAuthorityEntry.group(:local_authority_id).maximum(:updated_at)
        Qa::LocalAuthority.pluck(:id, :name).to_h do |id, name|
          # Sub-second precision: an edit and the reindex that follows it land inside
          # the same second often enough that a whole-second stamp misses the change.
          [name, "#{counts[id].to_i}-#{stamps[id]&.to_f}"]
        end
      end
    rescue ActiveRecord::StatementInvalid
      {}
    end

    # Upstream memoizes into @label_maps in front of Rails.cache, keyed by the
    # vocabulary name alone. The configured service is one object shared by every
    # Puma thread, so an instance memo would let a request in one tenant read a
    # map another tenant built. RequestStore is per thread and per request, which
    # is the scope a tenant actually has.
    def label_map(name)
      store = RequestStore.store[:hyku_controlled_vocabulary_label_maps] ||= {}
      # The full cache key, so this memo expires on a term edit for the same
      # reason Rails.cache does rather than pinning the map for the request.
      key = cache_key(name)
      return store[key] if store.key?(key)

      store[key] = Rails.cache.fetch(key, expires_in: self.class::CACHE_EXPIRATION) do
        build_label_map(name)
      end
    end
  end
end
