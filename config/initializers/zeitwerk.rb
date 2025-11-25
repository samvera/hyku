# frozen_string_literal: true

Rails.autoloaders.main.inflector.inflect(
  # Needed to let Zeitwerk find our overrides for the IIIFManifest gem
  "iiif_manifest" => "IIIFManifest"
)
