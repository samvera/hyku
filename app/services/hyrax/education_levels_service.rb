# frozen_string_literal: true
module Hyrax
  module EducationLevelsService
    extend Hyrax::AuthorityService

    authority_name 'education_levels'
    microdata_namespace 'type.'
  end
end
