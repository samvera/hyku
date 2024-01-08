# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource ImageResource`
class ImageResource < Hyrax::Work
  include Hyrax::Schema(:basic_metadata)
  include Hyrax::Schema(:image_resource)
  include Hyrax::ArResource
end
