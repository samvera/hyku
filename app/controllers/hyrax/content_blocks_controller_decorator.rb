# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 to add home_text to permitted_params - Adding themes

module Hyrax
  module ContentBlocksControllerDecorator
    private

    def permitted_params
      params.require(:content_block).permit(:marketing,
                                            :announcement,
                                            :home_text,
                                            :homepage_about_section_heading,
                                            :homepage_about_section_content,
                                            :researcher)
    end
  end
end

Hyrax::ContentBlocksController.prepend Hyrax::ContentBlocksControllerDecorator
