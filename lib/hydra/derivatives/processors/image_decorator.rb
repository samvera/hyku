# frozen_string_literal: true

# Fix PDF tripple issue

module Hydra
  module Derivatives
    module Processors
      module ImageDecorator
        protected

          # When resizing images, it is necessary to flatten any layers, otherwise the background
          # may be completely black. This happens especially with PDFs. See https://github.com/samvera/hydra-derivatives/issues/110
          def create_resized_image
            create_image do |xfrm|
              if size
                xfrm.combine_options do |i|
                  i.flatten
                  i.resize(size)
                end
              end
            end
          end
      end
    end
  end
end

::Hydra::Derivatives::Processors::Image.prepend(Hydra::Derivatives::Processors::ImageDecorator)
