# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 use site defaults over app default

module Hyrax
  module WorkThumbnailPathServiceDecorator
    def default_image
      Site.instance.default_work_image&.url || super
    end
  end
end

Hyrax::WorkThumbnailPathService.singleton_class.send(:prepend, Hyrax::WorkThumbnailPathServiceDecorator)
