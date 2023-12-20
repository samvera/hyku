# frozen_string_literal: true

# OVERRIDE Hyrax v3.4.0 to add home_text to permitted_params - Adding themes
module Hyrax
  module ContentBlocksControllerDecorator
    # override hyrax v2.9.0 added the home_text content block to permitted_params - Adding Themes
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
