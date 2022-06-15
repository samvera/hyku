# frozen_string_literal: true

# OVERRIDE Hryax v3.4.0
require_dependency Hyrax::Engine.root.join('app', 'services', 'hyrax', 'quick_classification_query').to_s

Hyrax::QuickClassificationQuery.class_eval do
  # OVERRIDE: only use work types that are enabled in the current tenant
  # @param [::User] user the current user
  # @param [#call] concern_name_normalizer (String#constantize) a proc that translates names to classes
  # @param [Array<String>] models the options to display, defaults to everything.
  def initialize(user,
                 models: Site.instance.available_works,
                 concern_name_normalizer: ->(str) { str.constantize })
    @user = user
    @concern_name_normalizer = concern_name_normalizer
    @models = models
  end

  # OVERRIDE: only use work types that are enabled in the current tenant
  #
  # @return true if the requested concerns is same as all avaliable concerns
  def all?
    # OVERRIDE: use Site.instance.available_works instead of Hyrax.config.registered_curation_concern_types
    models == Site.instance.available_works
  end
end
