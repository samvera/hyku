# frozen_string_literal: true

# Helpers for the heritage theme's home and show pages.
module HeritageHelper
  PANEL_ROWS = 10

  def hrt_home
    @hrt_home ||= Heritage::HomepagePresenter.new(
      search_service: controller.search_service,
      response: @response,
      collections: @collections,
      featured_work_list: @featured_work_list,
      featured_collection_list: @featured_collection_list,
      current_ability:
    )
  end

  def hrt_date_created(object)
    Array(object.date_created).first.presence
  end

  def hrt_file_set_ids(presenter)
    @hrt_file_set_ids ||= hrt_member_pages(presenter.authorized_file_set_ids,
                                           page: params[:files_page].to_s.to_i, per: PANEL_ROWS)
  end

  def hrt_child_work_ids(presenter)
    @hrt_child_work_ids ||= hrt_member_pages(presenter.authorized_child_work_ids,
                                             page: params[:items_page].to_s.to_i, per: PANEL_ROWS)
  end

  private

  # TODO: dedupe with practice_research pr_paginate — shared paginate-members helper
  def hrt_member_pages(ids, page:, per:)
    paged = Kaminari.paginate_array(ids, total_count: ids.size).page(page).per(per)

    paged.out_of_range? && paged.total_pages.positive? ? paged.page(paged.total_pages) : paged
  end
end
