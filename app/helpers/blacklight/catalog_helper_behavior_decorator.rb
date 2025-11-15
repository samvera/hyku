# frozen_string_literal: true

# OVERRIDE blacklight 7.9.0 to allow full url for show links for shared search thumbnail
module Blacklight
  module CatalogHelperBehaviorDecorator
    # rubocop:disable Metrics/MethodLength
    def render_thumbnail_tag(document, image_options = {}, url_options = {})
      value = if blacklight_config.view_config(document_index_view_type).thumbnail_method
                send(blacklight_config.view_config(document_index_view_type).thumbnail_method, document, image_options)
              elsif blacklight_config.view_config(document_index_view_type).thumbnail_field
                url = thumbnail_url(document)
                image_tag url, image_options if url.present?
              end

      # rubocop:disable Style/GuardClause
      if value
        if url_options == false
          Deprecation.warn(self, "passing false as the second argument to render_thumbnail_tag is deprecated. Use suppress_link: true instead. This behavior will be removed in Blacklight 7")
          # rubocop:enable Metrics/MethodLength
          url_options = { suppress_link: true }
        end
        if url_options[:suppress_link]
          value
        elsif url_options[:full_url]
          link_to generate_work_url(document.to_h, request) do
            value
          end
        else
          link_to_document document, value, url_options
        end
      end
      # rubocop:enable Style/GuardClause
    end
    # rubocop:enable Metrics/MethodLength

    def thumbnail_url(document)
      document = document.try(:solr_document) || document

      cname = document['account_cname_tesim']&.first
      return super if cname.nil?

      request.protocol + cname + super
    end
  end
end

Blacklight::CatalogHelperBehavior.prepend(Blacklight::CatalogHelperBehaviorDecorator)
