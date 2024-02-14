# frozen_string_literal: true

module Hyrax
  module ModelRegistryDecorator
    ##
    # Due to our convention of registering :image and :generic_work as the curation concern but
    # writing/creating ImageResource and GenericWorkResource, we need to amend the newly arrived
    # {Hyrax::ModelRegistry}.
    def work_class_names
      @work_class_names ||= super.flat_map { |name| name.end_with?("Resource") ? [name] : [name, "#{name}Resource"] }
    end
  end
end

Hyrax::ModelRegistry.singleton_class.send(:prepend, Hyrax::ModelRegistryDecorator)
