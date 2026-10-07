# frozen_string_literal: true

module Hyku
  module Mods
    ##
    # The XML of one MODS record, grown one mapped value at a time.
    #
    # Wrapper elements with the same name and attributes are shared across properties, so every
    # date lands in one +originInfo+. The exceptions are {PER_VALUE_WRAPPERS}, where each value
    # describes a different thing (each creator is its own +name+).
    class ElementTree
      NAMESPACE = 'http://www.loc.gov/mods/v3'
      SCHEMA_LOCATION = 'http://www.loc.gov/standards/mods/v3/mods-3-7.xsd'

      # A shared subject would read as one compound heading, and a shared language or place as one
      PER_VALUE_WRAPPERS = %w[name titleInfo relatedItem subject language place].freeze
      # Location's children must come in this order, and the work's own URLs are appended after any
      # mapped location children
      LOCATION_SEQUENCE = %w[physicalLocation shelfLocator url holdingSimple holdingExternal].freeze
      # Every element MODS 3.7 allows directly inside mods, listed in the conventional order of the
      # MODS outline; the schema itself accepts them in any order
      TOP_LEVEL_ELEMENTS = %w[
        titleInfo name typeOfResource genre originInfo language physicalDescription abstract
        tableOfContents targetAudience note subject classification relatedItem identifier location
        accessCondition part extension recordInfo
      ].freeze

      attr_reader :root

      def initialize
        xml = Nokogiri::XML::Document.new
        xml.root = xml.create_element(
          'mods',
          'xmlns' => NAMESPACE,
          'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'version' => '3.7',
          'xsi:schemaLocation' => "#{NAMESPACE} #{SCHEMA_LOCATION}"
        )
        @root = xml.root
      end

      # @param steps [Array<MappingPath::Step>]
      # @param entry [Hash, nil] the wrappers one compound entry has written so far, keyed by path,
      #   so its sub-properties share them at every level (one +name+ per creator, holding its
      #   role) whatever the per-value rule says
      # @return [Nokogiri::XML::Element] a new, empty leaf element for one value
      def add(steps, entry: nil)
        *wrappers, leaf = steps
        parent = wrappers.each_with_index.reduce(root) do |node, (step, depth)|
          if entry
            entry[wrappers[0..depth].map(&:to_h)] ||= append(node, step)
          else
            shared_child(node, step) || append(node, step)
          end
        end
        append(parent, leaf)
      end

      def shared_child(parent, step)
        return if PER_VALUE_WRAPPERS.include?(step.name) || step.children.any?
        parent.element_children.find do |child|
          child.name == step.name && child.attributes.transform_values(&:value) == step.attributes
        end
      end

      def element(parent, name, content = nil, attributes = {})
        parent.add_child(root.document.create_element(name, *content, attributes))
      end

      def to_xml
        reorder(root, TOP_LEVEL_ELEMENTS)
        root.xpath('.//mods:location', 'mods' => NAMESPACE).each { |location| reorder(location, LOCATION_SEQUENCE) }
        root.to_xml
      end

      private

      def append(parent, step)
        node = element(parent, step.name, nil, step.attributes)
        step.children.each do |child|
          leaf = child[:path].reduce(node) { |wrapper, name| element(wrapper, name) }
          leaf.content = child[:text]
        end
        node
      end

      def reorder(parent, order)
        parent.element_children
              .sort_by.with_index { |child, i| [order.index(child.name) || order.size, i] }
              .each { |child| parent.add_child(child) }
      end
    end
  end
end
