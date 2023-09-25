# frozen_string_literal: true

# OVERRIDE Hyrax 3.5 to add content blocks
module Hyrax
  module HomepageControllerDecorator
    def index
      @presenter = presenter_class.new(current_ability, collections)
      @featured_researcher = ContentBlock.for(:researcher)
      @marketing_text = ContentBlock.for(:marketing)
      @featured_work_list = FeaturedWorkList.new
      @announcement_text = ContentBlock.for(:announcement)
      @homepage_about_section_heading = ContentBlock.for(:homepage_about_section_heading)
      @homepage_about_section_content = ContentBlock.for(:homepage_about_section_content)
      recent
    end
  end
end

Hyrax::HomepageController.prepend Hyrax::HomepageControllerDecorator
