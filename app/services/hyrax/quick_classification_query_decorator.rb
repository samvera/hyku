# frozen_string_literal: true

# OVERRIDE Hryax v5.2.0

module Hyrax
  module QuickClassificationQueryDecorator
    # OVERRIDE: only use work types that are enabled in the current tenant
    # @param [::User] user the current user
    # @param [#call] concern_name_normalizer (String#constantize) a proc that translates names to classes
    # @param [Array<String>] models the options to display, defaults to everything.
    def initialize(user, models: filtered_available_works, **kwargs)
      super(user, **kwargs.merge(models:))
    end

    # OVERRIDE: only use work types that are enabled in the current tenant
    #
    # @return true if the requested concerns is same as all avaliable concerns
    def all?
      # OVERRIDE: use filtered_available_works instead of Hyrax.config.registered_curation_concern_types
      models == filtered_available_works
    end

    private

    # Filter available works based on metadata profile when flexible metadata is enabled
    def filtered_available_works
      available_works = Site.instance.available_works
      return available_works unless Hyrax.config.flexible?

      # Search-only tenants don't have their own flexible metadata profiles
      # They should use the basic available_works configuration
      return available_works if Site.account&.search_only?

      profile = Hyrax::FlexibleSchema.current_version
      return available_works unless profile

      profile_classes = profile['classes']&.keys || []
      profile_work_types = profile_classes.map { |klass| klass.gsub(/Resource$/, '') } & Hyrax.config.registered_curation_concern_types

      # Only include work types that are both enabled in site AND in the metadata profile
      available_works & profile_work_types
    end
  end
end

Hyrax::QuickClassificationQuery.prepend(Hyrax::QuickClassificationQueryDecorator)
