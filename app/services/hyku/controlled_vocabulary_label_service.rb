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
      RequestStore.store.delete(:hyku_controlled_vocabulary_label_maps)
      @local_authority_names = nil
    end

    private

    def database_backed?(name)
      Qa::LocalAuthority.exists?(name:)
    rescue ActiveRecord::StatementInvalid => e
      # No qa tables yet (early boot, a fresh database).
      Hyrax.logger.debug { "Unable to look up local authority #{name}: #{e.message}" }
      false
    end

    def cache_key(name)
      "#{super}-#{Apartment::Tenant.current}"
    end

    # Upstream memoizes into @label_maps in front of Rails.cache, keyed by the
    # vocabulary name alone. The configured service is one object shared by every
    # Puma thread, so an instance memo would let a request in one tenant read a
    # map another tenant built. RequestStore is per thread and per request, which
    # is the scope a tenant actually has.
    def label_map(name)
      store = RequestStore.store[:hyku_controlled_vocabulary_label_maps] ||= {}
      key = "#{Apartment::Tenant.current}-#{name}"
      return store[key] if store.key?(key)

      store[key] = Rails.cache.fetch(cache_key(name), expires_in: self.class::CACHE_EXPIRATION) do
        build_label_map(name)
      end
    end
  end
end
