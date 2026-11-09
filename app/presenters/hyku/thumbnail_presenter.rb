# frozen_string_literal: true

module Hyku
  class ThumbnailPresenter < Blacklight::ThumbnailPresenter
    def url
      thumbnail_value_from_document
    end

    private

    def thumbnail_value(image_options)
      super({ loading: 'lazy' }.merge(image_options))
    end

    def thumbnail_value_from_document
      path = super
      return path if path.blank?

      cname = document['account_cname_tesim']&.first
      return path if cname.blank? || cname == view_context.current_account&.cname

      view_context.request.protocol + cname + path
    end
  end
end
