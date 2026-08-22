# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to add select_active_options to module-level authority services
#
# Upstream's authority_name macro defines only select_all_options. Because
# Hyrax::FormHelperBehavior asks for select_active_options first and falls back to
# select_all_options, a service extending this module offered its retired terms. The
# class-based services subclass Hyrax::TolerantSelectService and were unaffected.
module Hyrax
  module AuthorityServiceDecorator
    def authority_name(subauthority_name)
      super

      # OVERRIDE: added alongside the readers upstream's macro defines.
      #
      # Tolerant of a missing flag, matching Hyrax::TolerantSelectService: a yaml
      # term may omit `active` altogether, and Hyrax treats such a term as usable.
      # Reading it as retired would empty the shipped vocabularies.
      define_singleton_method(:select_active_options) do
        authority.all
                 .select { |element| element.fetch('active', true) }
                 .map { |element| [element[:label], element[:id]] }
      end
    end
  end
end

Hyrax::AuthorityService.prepend(Hyrax::AuthorityServiceDecorator)
