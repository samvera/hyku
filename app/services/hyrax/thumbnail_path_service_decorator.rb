# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 - use site defaults instead of app wide defaults

module Hyrax
  module ThumbnailPathServiceDecorator
    def default_image
      Site.instance.default_work_image&.url || super
    end
  end
end

Hyrax::ThumbnailPathService.singleton_class.send(:prepend, Hyrax::ThumbnailPathServiceDecorator)
