# frozen_string_literal: true

# OVERRIDE Hyrax v5.0.0rc2 to increase the size of thumbnails

module Hyrax
  module FileSetDerivativesServiceDecorator
    def create_pdf_derivatives(filename)
      Hydra::Derivatives::PdfDerivatives.create(filename, outputs: [{ label: :thumbnail,
                                                                      format: 'jpg',
                                                                      size: '676x986',
                                                                      url: derivative_url('thumbnail'),
                                                                      layer: 0 }])
      extract_full_text(filename, uri)
    end

    def create_office_document_derivatives(filename)
      Hydra::Derivatives::DocumentDerivatives.create(filename, outputs: [{ label: :thumbnail,
                                                                           format: 'jpg',
                                                                           size: '600x450>',
                                                                           url: derivative_url('thumbnail'),
                                                                           layer: 0 }])
      extract_full_text(filename, uri)
    end

    def create_image_derivatives(filename)
      # We're asking for layer 0, because otherwise pyramidal tiffs flatten all the layers together into the thumbnail
      Hydra::Derivatives::ImageDerivatives.create(filename, outputs: [{ label: :thumbnail,
                                                                        format: 'jpg',
                                                                        size: '600x450>',
                                                                        url: derivative_url('thumbnail'),
                                                                        layer: 0 }])
    end
  end
end

Hyrax::FileSetDerivativesService.prepend(Hyrax::FileSetDerivativesServiceDecorator)
