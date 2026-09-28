# frozen_string_literal: true

# Helpers for the screening room theme's home and show pages.
module ScreeningRoomHelper
  def scr_home
    theme_home(ScreeningRoom::HomepagePresenter)
  end

  def scr_member_meta(member)
    visibility = theme_plain_text(member.permission_badge)
    uploaded = member.solr_document.date_uploaded

    return visibility if uploaded.blank?

    t('screening_room.show.items.meta', visibility:, date: l(uploaded, format: :long))
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
