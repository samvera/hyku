# frozen_string_literal: true

module Oai
  module Provider
    module MetadataFormat
      # Records render themselves through SolrDocument#to_mods
      class Mods < OAI::Provider::Metadata::Format
        include Hyku::OaiPmh::MappedFormat

        # rubocop:disable Lint/MissingSuper
        def initialize
          # rubocop:enable Lint/MissingSuper
          @prefix = 'mods'
          @schema = Hyku::Mods::ElementTree::SCHEMA_LOCATION
          @namespace = Hyku::Mods::ElementTree::NAMESPACE
          @element_namespace = 'mods'
          @fields = []
        end

        def feature
          :oai_mods
        end

        def mapping_key
          Hyku::Mods::MAPPING_KEY
        end
      end
    end
  end
end

OAI::Provider::Base.register_format(Oai::Provider::MetadataFormat::Mods.instance)
