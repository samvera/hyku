# frozen_string_literal: true
module Hyrax
  module AudienceService
    extend Hyrax::AuthorityService

    authority_name 'audience'
    microdata_namespace 'type.'
  end
end
