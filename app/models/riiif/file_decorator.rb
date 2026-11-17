# frozen_string_literal: true

module Riiif
  module FileDecorator
    extend ActiveSupport::Concern
    attr_reader :id
    include ActiveSupport::Benchmarkable

    def initialize(input_path, tempfile = nil, id: nil)
      super(input_path, tempfile)
      @id = id
    end

    # Wrap extract in a read lock and benchmark it
    def extract(transformation, image_info = nil)
      Riiif::Image.file_resolver.file_locks[id].with_read_lock do
        benchmark "RiiifFile extracted #{path} with #{transformation.to_params}", level: :debug do
          super
        end
      end
    end

    private

    def logger
      Hyrax.logger
    end
  end
end

Riiif::File.prepend(Riiif::FileDecorator)
