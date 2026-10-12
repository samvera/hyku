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

    def filtered_available_works
      Site.instance.offerable_work_types
    end
  end
end

Hyrax::QuickClassificationQuery.prepend(Hyrax::QuickClassificationQueryDecorator)
