# frozen_string_literal: true

# OVERRIDE blacklight-gallery 4.6.4 to strip the title's markup from the thumbnail alt text, which names the link
module Blacklight
  module Gallery
    module SlideshowPreviewComponentDecorator
      def populate_thumbnail_slot
        thumbnail_content = presenter.thumbnail.render({ alt: helpers.strip_tags(presenter.heading.to_s).squish }) if presenter.thumbnail.exists?
        thumbnail_content = content_tag(:div, t(:missing_image, scope: %i[blacklight_gallery catalog grid_slideshow]), class: 'thumbnail thumbnail-placeholder') if thumbnail_content.blank?
        with_thumbnail(thumbnail_content)
      end
    end
  end
end

Blacklight::Gallery::SlideshowPreviewComponent.prepend(Blacklight::Gallery::SlideshowPreviewComponentDecorator)
