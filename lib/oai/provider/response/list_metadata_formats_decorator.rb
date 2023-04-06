# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
module OAI::Provider::Response::ListMetadataFormatsDecorator
  def record_supports(record, prefix)
    (prefix == 'oai_dc') ||
      (prefix == 'oai_hyku') ||
      record.respond_to?("to_#{prefix}") ||
      record.respond_to?("map_#{prefix}")
  end
end
# rubocop:enable Style/ClassAndModuleChildren

OAI::Provider::Response::ListMetadataFormats.prepend(OAI::Provider::Response::ListMetadataFormatsDecorator)