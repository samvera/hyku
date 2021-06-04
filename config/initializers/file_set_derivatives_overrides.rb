# This file contains overrides to Hyrax::FileSetDerivativesService to increase the size of thumbnails

# Hyrax v2.9.0
Hyrax::FileSetDerivativesService.class_eval do
  # OVERRIDE: increase size of thumbnails for better viewing in Neutral theme home page
  def create_pdf_derivatives(filename)
    Hydra::Derivatives::PdfDerivatives.create(filename,
                                              outputs: [
                                                {
                                                  label: :thumbnail,
                                                  format: 'jpg',
                                                  size: '676x986',
                                                  url: derivative_url('thumbnail'),
                                                  layer: 0
                                                }
                                              ])
    extract_full_text(filename, uri)
  end

  def create_office_document_derivatives(filename)
    Hydra::Derivatives::DocumentDerivatives.create(filename,
                                                   outputs: [{
                                                     label: :thumbnail, format: 'jpg',
                                                     size: '600x450>',
                                                     url: derivative_url('thumbnail'),
                                                     layer: 0
                                                   }])
    extract_full_text(filename, uri)
  end

  def create_image_derivatives(filename)
    # We're asking for layer 0, becauase otherwise pyramidal tiffs flatten all the layers together into the thumbnail
    Hydra::Derivatives::ImageDerivatives.create(filename,
                                                outputs: [{ label: :thumbnail,
                                                            format: 'jpg',
                                                            size: '600x450>',
                                                            url: derivative_url('thumbnail'),
                                                            layer: 0 }])
  end
  
end