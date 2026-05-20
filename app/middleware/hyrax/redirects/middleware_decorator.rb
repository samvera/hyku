# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to fold the current tenant into the redirects
# resolver cache key. Two tenants can register the same alias path
# pointing at different resources; without the tenant prefix, the
# shared cache (Memcached/Redis) collides on the SHA1-hashed path and
# tenants poison each other's resolutions.

module Hyrax
  module Redirects
    module MiddlewareDecorator
      def cache_key_for(path)
        [Apartment::Tenant.current, super].join('/')
      end
    end
  end
end

Hyrax::Redirects::Middleware.singleton_class.prepend(Hyrax::Redirects::MiddlewareDecorator)
