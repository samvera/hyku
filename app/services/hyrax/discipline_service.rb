# frozen_string_literal: true
module Hyrax
  module DisciplineService
    extend Hyrax::AuthorityService

    authority_name 'discipline'
    microdata_namespace 'type.'
  end
end
