# frozen_string_literal: true

# Helpers for the reference theme's home page.
module ReferenceHomeHelper
  def ref_home
    @ref_home ||= Reference::HomepagePresenter.new(
      search_service: controller.search_service,
      response: @response,
      collections: @collections,
      featured_work_list: @featured_work_list,
      featured_collection_list: @featured_collection_list,
      current_ability:
    )
  end
end
