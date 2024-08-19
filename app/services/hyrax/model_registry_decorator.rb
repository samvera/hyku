# frozen_string_literal: true

module Hyrax
  module ModelRegistryDecorator
    ##
    # Due to our convention of registering :image and :generic_work as the curation concern but
    # writing/creating ImageResource and GenericWorkResource, we need to amend the newly arrived
    # {Hyrax::ModelRegistry}.
    def work_class_names
      # NOTE: It's unclear if we need both "GenericWork" and
      # "GenericWorkResource".  So if it turns out we only need one or the
      # other, no worries.
      @work_class_names ||= (super + Hyku::Application.work_types.map(&:to_s)).uniq
    end
  end
end

Hyrax::ModelRegistry.singleton_class.send(:prepend, Hyrax::ModelRegistryDecorator)
