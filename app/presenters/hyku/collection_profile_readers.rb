# frozen_string_literal: true

# OVERRIDE Hyrax v5.3.0 to give a flexible collection a reader for each profile property, named by the
# property's name, as Hyrax gives work and file set presenters; without one a collection page cannot show
# the property. A reader resolves the property per collection, from the profile version it was saved with and
# the entries available on its class, leaving out entries limited to a context, which an admin set sets for its works.
# TEMPORARY: re-evaluate and remove when samvera/hyrax#7732 is in the bundled Hyrax
module Hyku
  module CollectionProfileReaders
    def initialize(*)
      super
      define_profile_readers if @solr_document.try(:flexible?)
    end

    def self.readers
      @readers ||= Set.new
    end

    def profile_property(name)
      profile_properties[name.to_s]
    end

    def profile_properties
      @profile_properties ||= Hyrax::FlexibleSchema.profile_for(solr_document.schema_version).to_h.fetch('properties', {})
                                                   .each_with_object({}) do |(key, details), by_name|
        next unless available_on_this_class?(details) && Array(details.dig('available_on', 'context')).empty?

        by_name[details['name'] || key] = details
      end
    end

    def readable_term?(term)
      return false unless respond_to?(term)
      return profile_reader?(term) if CollectionProfileReaders.readers.include?(term.to_s)

      %i[size total_items].include?(term.to_sym) || solr_document.respond_to?(term) || compound_term?(term)
    end

    def profile_reader?(name)
      CollectionProfileReaders.readers.include?(name.to_s) && respond_to?(name) && solr_document.try(:flexible?) == true
    end

    private

    def define_profile_readers
      profile_properties.each do |name, details|
        next if self.class.method_defined?(name) || Object.private_method_defined?(name) || nested_or_compound?(details)

        CollectionProfileReaders.readers << name
        self.class.send(:define_method, name) do |*|
          document_value = solr_document.public_send(name) if solr_document.respond_to?(name)
          document_value.presence || profile_value(name)
        end
      end
    end

    def nested_or_compound?(details)
      details['type'] == 'hash' || details.dig('available_on', 'properties').present?
    end

    def available_on_this_class?(details)
      Array(details.dig('available_on', 'class')).map { |name| name.to_s.delete_prefix('::') }.include?(solr_document.hydra_model.to_s)
    end

    def profile_value(name)
      details = profile_property(name).to_h
      value = Array(details['indexing']).lazy.map { |index_key| solr_document[index_key] }.find(&:present?)
      return Array.wrap(value) if Hyrax::FlexibleSchema.multiple_values?(details)

      value || ''
    end
  end
end
