# frozen_string_literal: true

module Stanford
  module Importer
    # rubocop:disable Metrics/ClassLength
    class PurlParser
      DC_NS = { 'dc' => 'http://purl.org/dc/elements/1.1/' }.freeze

      attr_reader :xml

      def initialize(xml_file)
        @xml = Nokogiri::XML(xml_file)
      end

      def oai
        @oai ||= xml.xpath('//oai_dc:dc', 'oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/")
      end

      def model
        @model ||= if collection?
                     Collection
                   elsif image?
                     'Image'
                   else
                     'ETD'
                   end
      end

      def origin_text
        'Imported from PURL to local RDF profile by Hyku'
      end

      def collection?
        xml.xpath('//identityMetadata/objectType').any? { |c| c.text == 'collection' }
      end

      # For now the only things we import are collections and
      # images, so if it's not a collection, assume it's an image.
      def image?
        !collection?
      end

      def attributes
        if model == Collection
          collection_attributes
        else
          record_attributes
        end
      end

      def record_attributes
        common_attributes.merge(collection: collection)
                         .merge(files)
      end

      # @return [Hash] hash with a key :files, if there are any files.
      def files
        { files: xml.xpath('//contentMetadata/resource/file/@id').map(&:value) }
      end

      def collection_attributes
        common_attributes
      end

      def common_attributes
        description
          .merge(dates)
          .merge(locations)
          .merge(rights)
          .merge(visibility: visibility)
          .merge(identifiers)
          .merge(relations)
      end

      def description
        {
          title: untyped_title,
          description: dc_description,
          subject: subject,
          language: language,
          form_of_work: oai.xpath('./dc:format', DC_NS).map(&:text),
          resource_type: resource_type,
          record_origin: record_origin
        }
      end

      def language
        oai.xpath('./dc:language', DC_NS).map(&:text)
      end

      def resource_type
        oai.xpath('./dc:type', DC_NS).map(&:text)
      end

      def rights
        { rights: oai.xpath('./dc:rights', DC_NS).map(&:text) }
      end

      def visibility
        return 'open' if xml.xpath('//rightsMetadata/access[@type="read"]/machine/world').present?
        'restricted'
      end

      def depositor
        xml.xpath('//identityMetadata/objectCreator').text
      end

      def locations
        {
          location:
            oai.xpath('./dc:relation[@type="repository"]', DC_NS).map(&:text)
        }
      end

      def dates
        {
          created_attributes: oai.xpath('./dc:format', DC_NS).map(&:text)
        }
      end

      def identifiers
        { identifiers: oai.xpath('./dc:identifier', DC_NS).map(&:text),
          id: xml.xpath('//identityMetadata/objectId').text.sub('druid:', '') }
      end

      def record_origin
        [prepend_timestamp(origin_text)]
      end

      def dc_description
        oai.xpath('./dc:rights', DC_NS).map(&:text)
      end

      def relations
        contributors = oai.xpath('./dc:contributor', DC_NS).map(&:text)
        contributors.each_with_object({}) do |node, relations|
          relations[:contributor] ||= []
          relations[:contributor] << { name: [node] }
        end
      end

      def collection
        {
          id: collection_id,
          title: collection_name
        }
      end

      def collection_name
        oai.xpath('./dc:relation[@type="collection"]', DC_NS).map(&:text)
      end

      def collection_id
        ns = { 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
               'fedora' => 'info:fedora/fedora-system:def/relations-external#' }
        node_set = xml.xpath('//rdf:RDF/rdf:Description/fedora:isMemberOfCollection/@rdf:resource', ns)
        node_set.map { |n| n.value.sub('info:fedora/druid:', '') }.first
      end

      private

        def untyped_title
          oai.xpath('./dc:title', DC_NS).map(&:text)
        end

        def prepend_timestamp(text)
          "#{Time.now.utc.to_s(:iso8601)} #{text}"
        end

        def subject
          oai.xpath('./dc:subject', DC_NS).map(&:text)
        end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
