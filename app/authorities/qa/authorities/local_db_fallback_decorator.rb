# frozen_string_literal: true

# OVERRIDE Qa 5.x so a local vocabulary is served from the qa_local_authorities
# tables when the tenant has one, and from config/authorities otherwise.
module Qa::Authorities
  module LocalDbFallbackDecorator
    def subauthority_for(subauthority)
      resolved = super
      return resolved unless resolved.is_a?(Qa::Authorities::Local::FileBasedAuthority)

      Qa::Authorities::LocalVocabulary.new(subauthority)
    rescue Qa::InvalidSubAuthority
      raise unless Qa::LocalAuthority.exists?(name: subauthority)

      Qa::Authorities::LocalVocabulary.new(subauthority)
    end
  end
end

Qa::Authorities::Local.singleton_class.prepend(Qa::Authorities::LocalDbFallbackDecorator)
