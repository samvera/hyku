# frozen_string_literal: true
module Hyrax
  module BasicMetadataFormFieldsBehaviorDecorator
    def based_near_prepopulator
      self.based_near = based_near.map do |loc|
        uri = RDF::URI.parse(loc)
        if uri
          Hyrax::ControlledVocabularies::Location.new(uri)
        else
          loc
        end
      end
    end
  end
end

Hyrax::BasicMetadataFormFieldsBehavior.prepend(Hyrax::BasicMetadataFormFieldsBehaviorDecorator)
