# frozen_string_literal: true

module Hyrax
  module FileSetIndexerDecorator
    include IiifPrint::FileSetIndexer
  end
end

Hyrax::FileSetIndexer.prepend(Hyrax::FileSetIndexerDecorator)
