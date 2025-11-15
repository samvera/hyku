# frozen_string_literal: true

# OVERRIDE OAI v1.2.1 to add support for oai_hyku metadata format

module Oai::Provider::Response::ListMetadataFormatsDecorator
  def record_supports(record, prefix)
    (prefix == 'oai_dc') ||
      (prefix == 'oai_hyku') ||
      record.respond_to?("to_#{prefix}") ||
      record.respond_to?("map_#{prefix}")
  end
end

OAI::Provider::Response::ListMetadataFormats.prepend(Oai::Provider::Response::ListMetadataFormatsDecorator)
