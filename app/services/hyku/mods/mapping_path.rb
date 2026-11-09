# frozen_string_literal: true

require 'strscan'

module Hyku
  module Mods
    ##
    # Parses a +mods_oai_pmh+ mapping into the MODS elements a value is written under.
    #
    # Mappings are a restricted XPath: +mods:+-prefixed steps separated by +/+, where any step may
    # carry attribute predicates (+[@type="local"]+) or a child-value predicate
    # (+[mods:role/mods:roleTerm="creator"]+). Predicates become attributes and fixed child elements
    # on output. Anything else, such as +contains()+, raises {InvalidPath} rather than guessing.
    #
    # @example
    #   MappingPath.parse('mods:identifier[@type="local"]').steps.last.attributes
    #   # => { "type" => "local" }
    class MappingPath
      class InvalidPath < ArgumentError; end

      Step = Struct.new(:name, :attributes, :children, keyword_init: true)

      NAME = /mods:([A-Za-z][\w-]*)/
      QUOTED = /"([^"]*)"|'([^']*)'/

      attr_reader :steps

      def self.parse(string)
        new(string)
      end

      ##
      # Parses each mapping once per process, warning once about any MODS records cannot use.
      #
      # @return [MappingPath, nil] nil when the mapping is unsupported or does not fit the schema
      def self.cached(string)
        cache.compute_if_absent(string) do
          path = parse(string)
          problem = path.top_level? ? path.schema_error : "`#{path.steps.first.name}` is not a top-level MODS element"
          next path unless problem

          Rails.logger.warn("MODS mapping #{string.inspect}: #{problem}; it is left out of MODS records")
          false
        rescue InvalidPath => e
          Rails.logger.warn("#{e.message}; it is left out of MODS records")
          false
        end || nil
      end

      def self.cache
        @cache ||= Concurrent::Map.new
      end

      def top_level?
        ElementTree::TOP_LEVEL_ELEMENTS.include?(steps.first.name)
      end

      ##
      # Checks a one-value sample record against the MODS schema. What the leaf's own text may hold
      # depends on the data (digitalOrigin takes a fixed list, part's total a positive integer), so
      # errors about that value are not the mapping's.
      #
      # @return [String, nil] the schema's first objection to the path, or nil when it fits
      def schema_error
        tree = ElementTree.new
        leaf = tree.add(steps)
        leaf.content = 'value'
        about_leaf = "Element '{#{ElementTree::NAMESPACE}}#{leaf.name}': "
        leaf_value_errors = ["#{about_leaf}[facet", "#{about_leaf}'value' is not a valid value"]

        Mods.schema.validate(Nokogiri::XML(tree.to_xml))
            .map { |error| error.message.sub(/\A\d+:\d+: ERROR: /, '') }
            .reject { |message| message.start_with?(*leaf_value_errors) }
            .first&.remove("{#{ElementTree::NAMESPACE}}")
      end

      def initialize(string)
        @source = string.to_s.strip
        @scanner = StringScanner.new(@source)
        @steps = [scan_step]
        @steps << scan_step while @scanner.scan(%r{/})
        invalid! unless @scanner.eos?
      end

      private

      def scan_step
        name = scan_name
        step = Step.new(name:, attributes: {}, children: [])
        while @scanner.scan(/\[\s*/)
          attribute = scan_attribute
          attribute ? step.attributes.merge!(attribute) : step.children << scan_child
        end
        step
      end

      def scan_attribute
        return unless @scanner.scan(/@([A-Za-z][\w:-]*)\s*=\s*/)
        attribute = @scanner[1]
        { attribute => scan_value_and_close }
      end

      def scan_child
        path = [scan_name]
        path << scan_name while @scanner.scan(%r{/})
        @scanner.scan(/\s*=\s*/) || invalid!
        { path:, text: scan_value_and_close }
      end

      def scan_name
        @scanner.scan(NAME) || invalid!
        @scanner[1]
      end

      def scan_value_and_close
        @scanner.scan(QUOTED) || invalid!
        value = @scanner[1] || @scanner[2]
        @scanner.scan(/\s*\]/) || invalid!
        value
      end

      def invalid!
        raise InvalidPath, "Unsupported MODS mapping: #{@source.inspect}"
      end
    end
  end
end
