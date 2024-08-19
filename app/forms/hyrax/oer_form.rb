# frozen_string_literal: true
# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  # Generated form for Oer
  class OerForm < Hyrax::Forms::WorkForm
    include Hyrax::FormTerms
    self.model_class = ::Oer
    include HydraEditor::Form::Permissions
    include PdfFormBehavior

    self.terms = %i[admin_note title creator resource_type audience education_level learning_resource_type
                    discipline bibliographic_citation source rights_statement license rights_holder
                    rights_notes additional_information description subject language publisher oer_size
                    identifier table_of_contents alternative_title contributor related_url accessibility_feature
                    accessibility_hazard accessibility_summary representative_id thumbnail_id rendering_ids
                    newer_version_id previous_version_id alternate_version_id related_item_id keyword
                    date_created files visibility_during_embargo embargo_release_date visibility_after_embargo
                    visibility_during_lease lease_expiration_date visibility_after_lease visibility
                    ordered_member_ids in_works_ids member_of_collection_ids admin_set_id abstract]
    self.terms -= %i[previous_version_id newer_version_id alternate_version_id related_item_id]
    self.required_fields = %i[title creator resource_type date_created audience education_level learning_resource_type
                              discipline rights_statement]

    delegate :related_members_attributes=, :previous_version, :newer_version, :alternate_version, :related_item, to: :model
    include VideoEmbedFormBehavior

    def secondary_terms
      super - [:rendering_ids]
    end

    def self.build_permitted_params
      super + [
        {
          related_members_attributes: %i[id _destroy relationship]
        }
      ]
    end

    def previous_version_json
      previous_version.map do |child|
        {
          id: child.id,
          label: child.to_s,
          path: @controller.url_for(child),
          relationship: "previous-version"
        }
      end.to_json
    end

    def newer_version_json
      newer_version.map do |child|
        {
          id: child.id,
          label: child.to_s,
          path: @controller.url_for(child),
          relationship: "newer-version"
        }
      end.to_json
    end

    def alternate_version_json
      alternate_version.map do |child|
        {
          id: child.id,
          label: child.to_s,
          path: @controller.url_for(child),
          relationship: "alternate-version"
        }
      end.to_json
    end

    def related_item_json
      related_item.map do |child|
        {
          id: child.id,
          label: child.to_s,
          path: @controller.url_for(child),
          relationship: "related-item"
        }
      end.to_json
    end
  end
end
