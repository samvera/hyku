# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWorkResource`
#
# @see https://github.com/samvera/hyrax/wiki/Hyrax-Valkyrie-Usage-Guide#forms
# @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
class GenericWorkResourceForm < Hyrax::Forms::ResourceForm(GenericWorkResource)
  include Hyrax::FormFields(:basic_metadata) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:bulkrax_metadata) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:generic_work_resource) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:with_pdf_viewer) unless Hyrax.config.flexible?
  include Hyrax::FormFields(:with_video_embed) unless Hyrax.config.flexible?
  include Hyrax::BasedNearFieldBehavior unless Hyrax.config.flexible?
  include VideoEmbedBehavior::Validation
end
