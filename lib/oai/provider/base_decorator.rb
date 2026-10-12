# frozen_string_literal: true

# OVERRIDE OAI v1.3.0 to hide a metadata format that reports itself unavailable
module Oai::Provider::BaseDecorator
  def formats
    super.select { |_prefix, format| !format.respond_to?(:available?) || format.available? }
  end

  def format_supported?(prefix)
    formats.key?(prefix)
  end

  def format(prefix)
    raise OAI::FormatException unless format_supported?(prefix)
    super
  end
end

OAI::Provider::Base.prepend(Oai::Provider::BaseDecorator)
