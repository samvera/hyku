# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource OerResource`
#
# @see https://github.com/samvera/hyrax/wiki/Hyrax-Valkyrie-Usage-Guide#forms
# @see https://github.com/samvera/valkyrie/wiki/ChangeSets-and-Dirty-Tracking
class OerResourceForm < Hyrax::Forms::ResourceForm(OerResource)
  if Hyrax.config.work_include_metadata?
    # Commented out basic_metadata because the terms were added to the resource's yaml
    # so we can customize it
    # include Hyrax::FormFields(:basic_metadata)
    include Hyrax::FormFields(:bulkrax_metadata)
    include Hyrax::FormFields(:oer_resource)
    include Hyrax::FormFields(:with_pdf_viewer)
    include Hyrax::FormFields(:with_video_embed)
  end
  check_if_flexible(OerResource)
  include VideoEmbedBehavior::Validation
  # Define custom form fields using the Valkyrie::ChangeSet interface
  #
  # property :my_custom_form_field

  # if you want a field in the form, but it doesn't have a directly corresponding
  # model attribute, make it virtual
  #
  # property :user_input_not_destined_for_the_model, virtual: true

  delegate :related_members_attributes=, :previous_version, :newer_version, :alternate_version, :related_item,
           :previous_version_id, :newer_version_id, :alternate_version_id, :related_item_id, to: :model

  def self.build_permitted_params
    super + [
      {
        related_members_attributes: %i[id _destroy relationship]
      }
    ]
  end

  def previous_version_json
    return [] if previous_version.blank?

    previous_version.map do |child|
      {
        id: child.id.to_s,
        label: child.title.join(' | '),
        path: Rails.application.routes.url_helpers.url_for(child),
        relationship: "previous-version"
      }
    end.to_json
  end

  def newer_version_json
    return [] if newer_version.blank?

    newer_version.map do |child|
      {
        id: child.id.to_s,
        label: child.title.join(' | '),
        path: Rails.application.routes.url_helpers.url_for(child),
        relationship: "newer-version"
      }
    end.to_json
  end

  def alternate_version_json
    return [] if alternate_version.blank?

    alternate_version.map do |child|
      {
        id: child.id.to_s,
        label: child.title.join(' | '),
        path: Rails.application.routes.url_helpers.url_for(child),
        relationship: "alternate-version"
      }
    end.to_json
  end

  def related_item_json
    return [] if related_item.blank?

    related_item.map do |child|
      {
        id: child.id.to_s,
        label: child.title.join(' | '),
        path: Rails.application.routes.url_helpers.url_for(child),
        relationship: "related-item"
      }
    end.to_json
  end
end
