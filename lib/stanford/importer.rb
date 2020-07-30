# frozen_string_literal: true

module Stanford
  module Importer
    extend ActiveSupport::Autoload
    autoload :ModsParser
    autoload :PurlParser
    autoload :PurlRetriever
  end
end
