# frozen_string_literal: true

module Oai
  module Provider
    module MetadataFormat
      class HykuDublinCore < OAI::Provider::Metadata::Format
        class_attribute :fields, default: %i[
          identifier oai_id title abstract access_right accessibility_feature accessibility_hazard
          accessibility_summary additional_information advisor alternate_version_id alternative_title
          audience based_near bibliographic_citation committee_member contributor creator date_created
          degree_discipline degree_grantor degree_level degree_name department description discipline
          education_level extent format has_model keyword language learning_resource_type license
          newer_version_id oer_size previous_version_id publisher related_item_id related_url
          resource_type rights_holder rights_notes rights_statement source subject table_of_contents
          contributing_library library_catalog_identifier chronology_note
        ], instance_accessor: false

        # rubocop:disable Lint/MissingSuper
        def initialize
          # rubocop:enable Lint/MissingSuper
          @prefix = 'oai_hyku'
          @schema = 'http://dublincore.org/schemas/xmls/qdc/dcterms.xsd'
          @namespace = 'http://purl.org/dc/terms/'
          @element_namespace = 'hyku'

          # Dublin Core Terms Fields For new fields, add here first then add to
          # #map_oai_hyku on the model
          #
          # TODO: Can we derive these from the schema files?
          @fields = self.class.fields
        end

        # Override to strip namespace and header out
        # rubocop:disable Metrics/MethodLength
        def encode(model, record)
          xml = Builder::XmlMarkup.new
          map = model.respond_to?("map_#{prefix}") ? model.send("map_#{prefix}") : {}
          xml.tag!(prefix.to_s) do
            fields.each do |field|
              values = value_for(field, record, map)
              next if values.blank?

              if values.respond_to?(:each)
                values.each do |value|
                  xml.tag! field.to_s, value
                end
              else
                xml.tag! field.to_s, values
              end
            end
            add_repository(xml, record)
            add_public_file_urls(xml, record)
            add_thumbnail_url(xml, record)
          end
          xml.target!
        end
        # rubocop:enable Metrics/MethodLength

        # rubocop:disable Metrics/MethodLength
        def add_public_file_urls(xml, record)
          return if record[:member_ids_ssim].blank?

          fs_ids = record[:member_ids_ssim].join('" OR "')
          public_fs_ids = Hyrax::SolrService.query(
            "id:(\"#{fs_ids}\") AND " \
            "has_model_ssim:FileSet AND " \
            "visibility_ssi:#{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC}",
            fl: ["id"],
            method: :post,
            rows: 1024 # maximum
          )
          return if public_fs_ids.blank?

          public_fs_ids.each do |fs_id_hash|
            file_download_path = "https://#{Site.instance.account.cname}/downloads/#{fs_id_hash['id']}"
            xml.tag! 'file_url', file_download_path
          end
        end

        def add_thumbnail_url(xml, record)
          return if record[:thumbnail_path_ss].blank?
          thumbnail_url = "https://#{Site.instance.account.cname}#{record[:thumbnail_path_ss]}"
          xml.tag! 'thumbnail_url', thumbnail_url
        end

        def add_repository(xml, record)
          repo_name = Site.application_name || record[:account_cname_tesim].first
          xml.tag! 'repository', repo_name
        end

        def header_specification
          {
            'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
            'xmlns:oai_hyku' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
            'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
            'xmlns:dcterms' => "http://purl.org/dc/terms/",
            'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
            'xsi:schemaLocation' => "http://dublincore.org/schemas/xmls/qdc/dcterms.xsd"
          }
        end
      end
    end
  end
end

OAI::Provider::Base.register_format(Oai::Provider::MetadataFormat::HykuDublinCore.instance)
