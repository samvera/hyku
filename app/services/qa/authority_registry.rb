# frozen_string_literal: true

module Qa
  # Answers "what authorities does this installation offer, and how are they cited?"
  #
  # The qa gem knows all of this about itself but does not expose it: there is no
  # way to ask for the remote services it provides, and no display names for
  # either a service or its subauthorities. Every consumer therefore hardcodes a
  # list, which drifts from what the gem actually resolves — Hyku's own list named
  # 7 Library of Congress subauthorities where qa supports 43, and cited
  # `genre_forms` where qa accepts only `genreForms`.
  #
  # This is a Hyku class, named under Qa:: because everything it reasons about is.
  # The gem has no equivalent today.
  #
  # TODO: propose it upstream. It has no Hyku dependencies, so the gem could take it
  # over and this file be deleted — as something like Qa::Authorities.remote_services
  # and .vocabularies_for. DISPLAY_NAMES is the part that may not belong there, being
  # presentation rather than capability.
  class AuthorityRegistry
    # Constants under Qa::Authorities that are not vocabulary services: the local
    # backend, abstract bases, the subauthority mixins, the separately-configured
    # RDF mechanism, and the MeSH import helpers.
    NON_SERVICES = %w[
      Base WebServiceBase AuthorityWithSubAuthority Local LinkedData MeshTools
    ].freeze

    # qa names its classes for the code rather than the reader.
    SOURCE_KEYS = { 'assign_fast' => 'fast' }.freeze

    # titleize mangles acronyms and camelCase keys, and an acronym expanded wrongly
    # is worse than none.
    DISPLAY_NAMES = {
      'aat' => 'Art & Architecture Thesaurus',
      'tgn' => 'Thesaurus of Geographic Names',
      'ulan' => 'Union List of Artist Names',
      'iso639-1' => 'ISO 639-1 Languages',
      'iso639-2' => 'ISO 639-2 Languages',
      'iso639-3' => 'ISO 639-3 Languages',
      'iso639-5' => 'ISO 639-5 Languages',
      'genreForms' => 'Genre/Form Terms',
      'childrensSubjects' => "Children's Subjects",
      'performanceMediums' => 'Performance Mediums',
      'graphicMaterials' => 'Graphic Materials',
      'ethnographicTerms' => 'Ethnographic Terms',
      'geographicAreas' => 'Geographic Areas'
    }.freeze

    class << self
      # The remote services the gem provides, as the source key a metadata profile
      # cites => the authority class.
      #
      # Selected by where the constant is declared, so authorities a host
      # application adds are excluded without naming them: Hyrax contributes
      # pickers for works and collections, and Hyku its own local classes.
      #
      # Memoized for the life of the process: the walk loads and locates every
      # constant under Qa::Authorities, the index asks once per remote vocabulary,
      # and what the gem provides cannot change while the process runs. Unlike the
      # local authorities, none of this is per-tenant.
      #
      # @return [Hash{String => Module}]
      def remote_services
        @remote_services ||= build_remote_services
      end

      # Every vocabulary a service offers, as the keys a profile can cite.
      #
      # @return [Array<String>] e.g. ["loc/subjects", "geonames"]
      def vocabularies_for(source_key, klass)
        subauthorities_of(klass).map { |sub| [source_key, sub].compact.join('/') }
      end

      # @return [String] a name for a service or one of its vocabularies
      def display_name(key)
        DISPLAY_NAMES.fetch(key) { key.titleize }
      end

      # Nil means the service is a single vocabulary, cited by its own key alone
      # (`geonames`) rather than `service/vocabulary`.
      def subauthorities_of(klass)
        return [nil] unless klass.respond_to?(:subauthorities)

        klass.subauthorities.presence || [nil]
      end

      private

      def build_remote_services
        Qa::Authorities.constants.sort.each_with_object({}) do |name, services|
          next if NON_SERVICES.include?(name.to_s)
          next if name.to_s.end_with?('Subauthority', 'Decorator')

          # Loaded before locating it: qa autoloads these, and
          # const_source_location reports the autoload stub until the constant is
          # referenced.
          klass = authority_class(name)
          next if klass.nil?
          next unless defined_in_gem?(name)

          services[source_key_for(name)] = klass
        end
      end

      # Rescued per constant: some authorities read a config file when they load
      # (Oclcts wants config/oclcts-authorities.yml), and one missing file must not
      # empty the whole list.
      def authority_class(name)
        Qa::Authorities.const_get(name)
      rescue StandardError, LoadError => e
        Rails.logger.debug { "Skipping authority #{name}: #{e.message}" }
        nil
      end

      # Reads where the constant is declared, which is stable: inspecting the
      # class's methods would follow inherited ones into the gem, and would also be
      # perturbed by any method a test stubs onto the class.
      def defined_in_gem?(name)
        path, = Qa::Authorities.const_source_location(name)

        path.to_s.include?('questioning_authority')
      rescue StandardError => e
        Rails.logger.debug { "Unable to locate authority #{name}: #{e.message}" }
        false
      end

      def source_key_for(constant_name)
        key = constant_name.to_s.underscore
        SOURCE_KEYS.fetch(key, key)
      end
    end
  end
end
