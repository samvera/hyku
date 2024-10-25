# frozen_string_literal: true

# OVERRIDE Blacklight 7.35 to pass the query parameters to the UV via the thumbnail URL
module Blacklight
  module ThumbnailPresenterDecorator
    ##
    # Render the thumbnail, if available, for a document and
    # link it to the document record.
    #
    # @param [Hash] image_options to pass to the image tag
    # @param [Hash] url_options to pass to #link_to_document
    # @return [String]
    def thumbnail_tag(image_options = {}, url_options = {})
      value = thumbnail_value(image_options)
      return value if value.nil? || url_options[:suppress_link]
      view_context.link_to_document document, value, url_options
    end
  end
end

Blacklight::ThumbnailPresenter.prepend(Blacklight::ThumbnailPresenterDecorator)
