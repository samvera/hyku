# frozen_string_literal: true

module Hyku
  module Mods
    class RecordBuilder
      # MODS types that accept authority attributes, so may carry a controlled value's URI
      AUTHORITY_ELEMENTS = %w[
        classification form genre geographic languageTerm occupation physicalLocation placeTerm
        publisher roleTerm scriptTerm targetAudience temporal topic typeOfResource
      ].freeze
      TITLE_MAPPING = 'mods:titleInfo/mods:title'
      LOCATION = MappingPath::Step.new(name: 'location', attributes: {}, children: []).freeze

      ##
      # @param document [SolrDocument]
      # @param mappings [Array<Hash>] from SolrDocument#schema_data_for
      # @param compounds [Array<Hash>] from SolrDocument#compound_schema_data_for
      def initialize(document, mappings:, compounds: [], item_url: nil, thumbnail_url: nil)
        @document = document
        @mappings = mappings
        @compounds = compounds
        @item_url = item_url
        @thumbnail_url = thumbnail_url
        @tree = ElementTree.new
      end

      def to_xml
        values = OaiPmh::MappedValues.new(document, mappings, compounds: @compounds, title_mapping: TITLE_MAPPING)
        values.each do |mapping, mapped|
          path = MappingPath.cached(mapping)
          mapped.each { |value| write_value(tree.add(path.steps), value) } if path
        end
        values.each_compound_entry { |pairs| add_entry(pairs) }
        add_urls
        add_record_info
        tree.to_xml
      end

      private

      attr_reader :document, :mappings, :tree

      def add_entry(pairs)
        entry = {}
        pairs.each do |mapping, value|
          path = MappingPath.cached(mapping)
          write_value(tree.add(path.steps, entry:), value) if path
        end
      end

      def write_value(element, value)
        element.content = value.controlled? ? value.label : value.stored
        return unless value.controlled?

        if element.name == 'accessCondition'
          element['xlink:href'] = value.stored
        elsif AUTHORITY_ELEMENTS.include?(element.name)
          element['valueURI'] = value.stored
        end
      end

      def add_urls
        return unless @item_url || @thumbnail_url

        location = tree.shared_child(tree.root, LOCATION) || tree.element(tree.root, 'location')
        tree.element(location, 'url', @item_url, 'usage' => 'primary', 'access' => 'object in context') if @item_url
        tree.element(location, 'url', @thumbnail_url, 'access' => 'preview') if @thumbnail_url
      end

      def add_record_info
        info = tree.element(tree.root, 'recordInfo')
        tree.element(info, 'recordIdentifier', document.id)
        { 'recordCreationDate' => 'system_create_dtsi', 'recordChangeDate' => 'system_modified_dtsi' }.each do |name, field|
          tree.element(info, name, document[field].to_s, 'encoding' => 'iso8601') if document[field].present?
        end
      end
    end
  end
end
