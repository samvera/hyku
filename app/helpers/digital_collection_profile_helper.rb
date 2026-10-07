# frozen_string_literal: true

# Reads the flexible metadata (M3) profile's view settings for a document's model.
module DigitalCollectionProfileHelper
  def dc_profile_view_definitions(document)
    model = dc_profile_model(document)
    @dc_profile_view_definitions ||= {}
    @dc_profile_view_definitions[[model, document.schema_version, document.contexts]] ||=
      Hyrax::Schema.m3_schema_loader.view_definitions_for(schema: model, version: document.schema_version, contexts: document.contexts)
  end

  def dc_profile_shows?(presenter, field)
    return true unless Hyrax.config.flexible?

    options = dc_profile_view_definitions(presenter.solr_document)[field.to_sym]
    options.nil? || field_visible?(conform_options(field, options.deep_dup.with_indifferent_access), presenter)
  end

  def dc_profile_model(document)
    Valkyrie.config.resource_class_resolver.call(Array(document['has_model_ssim']).first || Hyrax.config.collection_model).to_s
  end
end
