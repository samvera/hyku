# frozen_string_literal: true
module Hyrax
  module LearningResourceTypesService
    extend Hyrax::AuthorityService

    authority_name 'learning_resource_types'
    microdata_namespace 'type.'
  end
end
