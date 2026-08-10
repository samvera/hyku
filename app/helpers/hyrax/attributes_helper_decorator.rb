# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0: under flexible metadata, attributes render per the
# m3 profile's view definitions, and the profile Hyku shipped marked license
# as render_as: external_link - so licenses render as bare URIs instead of
# their authority labels, and every tenant seeded from that profile carries
# the setting in its stored schema. For these authority-backed fields the
# semantic renderer always wins: the label still links to the URI, so an
# external_link rendering is strictly worse, and forcing it here heals
# existing tenants without a schema migration. The shipped profile is fixed
# alongside so new tenants agree with the code.
#
# TEMPORARY BRIDGE: this fix is upstreamed as samvera/hyrax#7575, which puts
# the same logic in Hyrax::AttributesHelper#conform_options itself. Once the
# pinned hyrax revision includes that change, delete this decorator and its
# spec - the behavior is identical and double-application is a no-op.
module Hyrax
  module AttributesHelperDecorator
    SEMANTIC_RENDERERS = {
      license: :license,
      rights_statement: :rights_statement
    }.freeze

    def conform_options(field_name, view_options)
      options = super
      semantic = SEMANTIC_RENDERERS[field_name.to_sym]
      options[:render_as] = semantic if semantic
      options
    end
  end
end

Hyrax::AttributesHelper.prepend(Hyrax::AttributesHelperDecorator)
