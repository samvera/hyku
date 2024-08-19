# frozen_string_literal: true

# NOTE: Changes here need to be added to model's #map_oai_hyku method.

OAI::Provider::MetadataFormat::HykuDublinCore.fields = %i[
  identifier oai_id title abstract access_right accessibility_feature accessibility_hazard
  accessibility_summary additional_information advisor alternate_version_id alternative_title
  audience based_near bibliographic_citation committee_member contributor creator date_created
  degree_discipline degree_grantor degree_level degree_name department description discipline
  education_level extent format has_model keyword language learning_resource_type license
  newer_version_id oer_size previous_version_id publisher related_item_id related_url
  resource_type rights_holder rights_notes rights_statement source subject table_of_contents
  contributing_library library_catalog_identifier chronology_note
]
