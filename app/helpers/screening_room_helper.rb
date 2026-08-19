# frozen_string_literal: true

# Helpers for the screening room theme's home and show pages.
module ScreeningRoomHelper
  def scr_home
    @scr_home ||= ScreeningRoom::HomepagePresenter.new(
      search_service: controller.search_service,
      featured_work_list: @featured_work_list,
      current_ability:,
      request:
    )
  end

  def scr_player_kind(representative)
    return if representative.blank?

    document = representative.solr_document
    return unless can?(:download, document)
    return :video if document.video?
    return :audio if document.audio?

    :image if document.image? && representative.original_file_id.present?
  end

  def scr_lightbox_url(representative)
    Hyrax.config.iiif_image_url_builder.call(
      representative.original_file_id, request.base_url, '!1200,1200', format: 'image/jpeg'
    )
  end
end
