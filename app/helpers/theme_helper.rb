# frozen_string_literal: true

# Presentation helpers shared by the Hyku themes.
module ThemeHelper
  include ThemeColorHelper

  MEMBER_ROWS = 10
  MAX_MEMBER_PAGE = 10_000

  def theme_plain_text(html)
    # strip_tags re-escapes what it returns, and every consumer escapes again on
    # the way out, so an ampersand would reach the reader as &amp;
    CGI.unescapeHTML(strip_tags(CGI.unescapeHTML(html.to_s).gsub('>', '> ')).squish)
  end

  def theme_blurb(text, length:)
    return if text.blank?

    truncate(theme_plain_text(text), length:, separator: ' ')
  end

  def theme_citations(presenter)
    { 'apa' => export_as_apa_citation(presenter),
      'mla' => export_as_mla_citation(presenter),
      'chicago' => export_as_chicago_citation(presenter) }.select { |_style, text| text.present? }
  end

  def theme_viewer?(presenter)
    presenter.video_embed_viewer? ||
      (presenter.representative_id.present? && presenter.representative_presenter.present?)
  end

  def theme_thumbnail_url(document, default: :work)
    indexed = document.try(:[], 'thumbnail_path_ss').presence
    return indexed if indexed && !indexed.include?('/assets/')

    return Site.instance.default_collection_image&.url || image_path('default.png') if default == :collection

    Site.instance.default_work_image&.url || indexed || image_path('default.png')
  end

  def theme_home(presenter_class)
    @theme_home ||= presenter_class.new(
      search_service: controller.search_service,
      response: @response,
      collections: @collections,
      featured_work_list: @featured_work_list,
      featured_collection_list: @featured_collection_list,
      current_ability:
    )
  end

  def theme_file_set_ids(presenter, per: MEMBER_ROWS)
    @theme_file_set_ids ||= paginate_members(presenter.authorized_file_set_ids, :files_page, per:)
  end

  def theme_child_work_ids(presenter, per: MEMBER_ROWS)
    @theme_child_work_ids ||= paginate_members(presenter.authorized_child_work_ids, :items_page, per:)
  end

  def theme_active_pane(panes)
    keys = panes.map(&:first)
    requested = params[:pane].to_s.to_sym

    keys.include?(requested) ? requested : keys.first
  end

  def theme_show_collection(presenter)
    @theme_show_collection ||= Hyrax::CollectionMemberService.run(presenter.solr_document, current_ability).first
  end

  def theme_share_work?
    @presenter&.display_share_button? && !Flipflop.read_only?
  end

  def theme_deposit_target
    return [hyrax.my_works_path, {}] unless signed_in?

    deposit_new_work_target(many: @presenter.create_many_work_types?, first_type: @presenter.first_work_type)
  end

  def theme_type_label(object)
    Array(object.resource_type).first.presence || object.human_readable_type
  end

  def theme_license_badge(presenter)
    license = Array(presenter.try(:license)).first.to_s
    return 'CC0 1.0' if license.include?('creativecommons.org/publicdomain/zero/1.0')

    match = license.match(%r{creativecommons\.org/licenses/([a-z-]+)/(\d+\.\d+)})
    return unless match

    "CC #{match[1].upcase} #{match[2]}"
  end

  private

  def paginate_members(ids, param_name, per: MEMBER_ROWS)
    paged = Kaminari.paginate_array(ids, total_count: ids.size)
                    .page(theme_positive_param(param_name, 1, MAX_MEMBER_PAGE))
                    .per(per)

    paged.out_of_range? && paged.total_pages.positive? ? paged.page(paged.total_pages) : paged
  end

  def theme_positive_param(name, fallback, ceiling)
    digits = params[name].to_s[/\d+/]

    digits.blank? ? fallback : digits.to_i.clamp(1, ceiling)
  end
end
