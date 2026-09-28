# frozen_string_literal: true

# OVERRIDE IiifPrint v3.1.0 IiifPrint::IiifSearchDecorator
module Hyku
  module IiifSearchDecorator
    def solr_params
      params = super
      return params unless Flipflop.iiif_ranges?

      child_ids = parent_document['descendent_member_ids_ssim'].to_a - [parent_document.id]
      return params if child_ids.empty?

      relation = iiif_config[:object_relation_field]
      child_clauses = child_ids.map { |id| "#{relation}:\"#{id}\"" }.join(" OR ")
      params[:q] = params[:q].sub(
        "#{relation}:\"#{parent_document.id}\"",
        "(#{relation}:\"#{parent_document.id}\" OR #{child_clauses})"
      )
      params
    end
  end
end

::BlacklightIiifSearch::IiifSearch.prepend(Hyku::IiifSearchDecorator)
