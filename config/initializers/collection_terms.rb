# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to let an app list a collection page's fields, in order, with
# Hyrax.config.collection_terms (see docs/configuration.md, "Which fields a collection page lists")
# TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax
Hyrax::Configuration.send(:attr_accessor, :collection_terms)
