module Importer
  module Factory
    class ImageFactory < ObjectFactory
      include WithAssociatedCollection

      self.klass = Image
      # A way to identify objects that are not Hydra minted identifiers
      self.system_identifier_field = :identifier

      # TODO: add resource type?
      # def create_attributes
      #   #super.merge(resource_type: 'Image')
      # end
    end
  end
end
