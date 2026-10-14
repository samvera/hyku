# frozen_string_literal: true

module Hyrax
  module MediaViewerService
    extend Hyrax::AuthorityService

    authority_name 'media_viewer'
    microdata_namespace 'type.'
  end
end
