# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource ImageResource`
#
# @see https://github.com/samvera/hyrax/wiki/Hyrax-Valkyrie-Usage-Guide#forms
# @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
class ImageResourceForm < Hyrax::Forms::ResourceForm(ImageResource)
  if Hyrax.config.work_include_metadata?
    include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields(:bulkrax_metadata)
    include Hyrax::FormFields(:image_resource)
    include Hyrax::FormFields(:with_pdf_viewer)
    include Hyrax::FormFields(:with_video_embed)
  end
  check_if_flexible(ImageResource)

  include VideoEmbedBehavior::Validation
end
