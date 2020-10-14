# frozen_string_literal: true

module Importer
  module Factory
    class ETDFactory < ObjectFactory
      include WithAssociatedCollection

      self.klass = GenericWork
      # A way to identify objects that are not Hydra minted identifiers
      self.system_identifier_field = :identifier

      # TODO: add resource type?
      # def create_attributes
      #   #super.merge(resource_type: 'ETD')
      # end
    end
  end
end
