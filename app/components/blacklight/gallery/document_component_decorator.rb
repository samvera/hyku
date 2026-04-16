# frozen_string_literal: true

# OVERRIDE blacklight-gallery 4.6.4 to pass alt text to thumbnail image options
module Blacklight
  module Gallery
    module DocumentComponentDecorator
      def before_render
        with_thumbnail(image_options: { class: 'img-thumbnail', alt: helpers.thumbnail_alt_text_for(@document || @presenter&.document) }) if thumbnail.blank?
        super
      end
    end
  end
end

Blacklight::Gallery::DocumentComponent.prepend(Blacklight::Gallery::DocumentComponentDecorator)
