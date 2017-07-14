module Importer
  module Factory
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :CollectionFactory
      autoload :ETDFactory
      autoload :ImageFactory
      autoload :ObjectFactory
      autoload :StringLiteralProcessor
      autoload :WithAssociatedCollection
    end

    def self.for(model_name)
      const_get "#{model_name}Factory"
    end
  end
end
