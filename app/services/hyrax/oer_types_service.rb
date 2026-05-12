# frozen_string_literal: true
module Hyrax
  module OerTypesService
    extend Hyrax::AuthorityService

    authority_name 'oer_types'
    microdata_namespace 'type.'
  end
end
