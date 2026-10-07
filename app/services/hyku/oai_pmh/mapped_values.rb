# frozen_string_literal: true

module Hyku
  module OaiPmh
    ##
    # What a SolrDocument holds for each property mapped under one OAI-PMH mappings key, so formats
    # read values alike and differ only in how they write each mapping and value.
    #
    # @example From a format's SolrDocument#to_<prefix>
    #   values = MappedValues.new(self, schema_data_for('mods_oai_pmh').to_a,
    #                             compounds: compound_schema_data_for('mods_oai_pmh').to_a,
    #                             title_mapping: 'mods:titleInfo/mods:title')
    #   values.each { |mapping, mapped| ... }
    #   values.each_compound_entry { |pairs| ... }
    class MappedValues
      Value = Struct.new(:stored, :label, keyword_init: true) do
        # A controlled vocabulary term, stored as a URI with a label in the index
        def controlled?
          label.present? && stored.match?(%r{\Ahttps?://})
        end
      end

      ##
      # @param mappings [Array<Hash>] from SolrDocument#schema_data_for, which is nil for a model
      #   with neither a profile nor a schema, so pass it through +to_a+
      # @param compounds [Array<Hash>] from SolrDocument#compound_schema_data_for, likewise +to_a+
      # @param title_mapping [String] where the format writes title when no mapping covers it
      def initialize(document, mappings, title_mapping:, compounds: [])
        @document = document
        @compounds = compounds
        # A compound's sub-properties are also indexed flat, which would lose which values belong
        # to the same entry
        subproperties = compounds.flat_map { |compound| compound[:subproperties].filter_map { |sub| sub[:property] } }
        @mappings = mappings.reject { |item| subproperties.include?(item[:property].to_s) }
        @title_mapping = title_mapping
      end

      ##
      # @yieldparam mapping [String] the property's mapping, as the profile or YAML writes it
      # @yieldparam values [Array<Value>]
      def each
        written = Set.new
        mappings_with_title.each do |item|
          field = value_field(item[:index_keys])
          # Profile properties can share an index field (creator and creator_hidden)
          next unless field && written.add?([field, item[:mapping]])

          stored = Array.wrap(@document[field]).map(&:to_s).compact_blank
          labels = labels_for(field, stored)
          yield item[:mapping], stored.each_with_index.map { |value, i| Value.new(stored: value, label: labels[i]) }
        end
      end

      ##
      # One compound entry at a time, such as one creator with their role.
      #
      # @yieldparam pairs [Array<Array(String, Value)>] each mapped sub-property's mapping and value
      def each_compound_entry
        @compounds.each do |compound|
          entries_for(compound[:compound]).each do |entry|
            pairs = compound[:subproperties].flat_map do |sub|
              Array.wrap(entry[sub[:key]]).map(&:to_s).compact_blank.map { |value| [sub[:mapping], Value.new(stored: value)] }
            end
            yield pairs if pairs.any?
          end
        end
      end

      private

      def entries_for(compound)
        Hyrax::SolrDocument::Metadata::Solr::CompoundEntries.coerce(@document["#{compound}_json_ss"])
      end

      # Title is core metadata, with no mapping in Hyrax's core_metadata.yaml, as it is for oai_dc
      def mappings_with_title
        return @mappings if @mappings.any? { |item| item[:property].to_s == 'title' }
        [{ property: 'title', mapping: @title_mapping, index_keys: ['title_tesim'] }] + @mappings
      end

      def value_field(index_keys)
        keys = Array(index_keys).map(&:to_s)
        (keys.select { |key| key.end_with?('_tesim') } + keys).find { |key| @document[key].present? }
      end

      # The indexer writes a controlled value's labels, in the same order, to the field this names
      def labels_for(field, values)
        label_field = Hyrax::ControlledVocabularyFieldValues.label_key(field)
        labels = label_field == field ? [] : Array.wrap(@document[label_field])
        labels.size == values.size ? labels : []
      end
    end
  end
end
