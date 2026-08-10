# frozen_string_literal: true

module PracticeResearchShowHelper
  VISIBLE_METADATA_ROWS = 8
  MAX_ROWS = 100
  MAX_PAGE = 10_000
  DEFAULT_ROWS = 20

  def pr_show_panes(presenter)
    @pr_show_panes ||= [].tap do |panes|
      panes << [:context, t('practice_research.show.tabs.context')] if pr_section_present?(pr_context_html(presenter))
      panes << [:metadata, t('practice_research.show.tabs.metadata')]

      children = pr_child_work_ids(presenter)
      files = pr_file_set_ids(presenter)
      panes << [:items, "#{pr_items_label(presenter)} (#{children.total_count})"] if children.any?
      panes << [:files, "#{t('practice_research.show.tabs.files')} (#{files.total_count})"] if files.any?
    end
  end

  def pr_active_pane(presenter)
    keys = pr_show_panes(presenter).map(&:first)
    requested = params[:pane].to_s.to_sym

    keys.include?(requested) ? requested : keys.first
  end

  def pr_context_html(presenter)
    @pr_context_html ||= render('featured_attributes', presenter:).to_s
  end

  def pr_items_label(presenter)
    t("practice_research.show.items.#{presenter.model_name.param_key}",
      default: t('practice_research.show.items.default'))
  end

  def pr_section_present?(html)
    Nokogiri::HTML.fragment(html.to_s).text.strip.present?
  end

  def pr_viewer?(presenter)
    presenter.video_embed_viewer? ||
      (presenter.representative_id.present? && presenter.representative_presenter.present?)
  end

  def pr_file_set_ids(presenter)
    @pr_file_set_ids ||= pr_paginate(presenter.authorized_file_set_ids, :files_page)
  end

  def pr_child_work_ids(presenter)
    @pr_child_work_ids ||= pr_paginate(presenter.authorized_child_work_ids, :items_page)
  end

  def pr_file_sets(presenter)
    @pr_file_sets ||= presenter.member_presenters(pr_file_set_ids(presenter))
  end

  def pr_child_works(presenter)
    @pr_child_works ||= presenter.member_presenters(pr_child_work_ids(presenter))
  end

  def pr_metadata_rows(presenter, visible: VISIBLE_METADATA_ROWS)
    rows = pr_metadata_fields(presenter)

    [rows.first(visible), rows.drop(visible)]
  end

  def pr_metadata_fields(presenter)
    view_options_for(presenter).filter_map do |field, options|
      next if compound_card_field?(presenter, field)

      view_options = conform_options(field, options)
      render_field = conform_field(field, options)

      next unless field == :admin_note ? presenter.editor? : field_visible?(view_options, presenter)

      next unless presenter.respond_to?(render_field)
      next if Array(presenter.public_send(render_field)).reject(&:blank?).blank?

      [render_field, view_options]
    end
  end

  def pr_card_fields(presenter)
    names = compound_schema_for(presenter).card_compound_names - %i[participants relationships]

    names.select { |field| presenter.respond_to?(field) && presenter.public_send(field).present? }
  end

  def pr_license_badge(presenter)
    license = Array(presenter.try(:license)).first.to_s
    return 'CC0 1.0' if license.include?('creativecommons.org/publicdomain/zero/1.0')

    match = license.match(%r{creativecommons\.org/licenses/([a-z-]+)/(\d+\.\d+)})
    return unless match

    "CC #{match[1].upcase} #{match[2]}"
  end

  private

  def pr_paginate(ids, param_name)
    paged = Kaminari.paginate_array(ids, total_count: ids.size)
                    .page(pr_positive_param(param_name, 1, MAX_PAGE))
                    .per(pr_positive_param(:rows, DEFAULT_ROWS, MAX_ROWS))

    paged.out_of_range? && paged.total_pages.positive? ? paged.page(paged.total_pages) : paged
  end

  def pr_positive_param(name, fallback, ceiling)
    digits = params[name].to_s[/\d+/]

    digits.blank? ? fallback : digits.to_i.clamp(1, ceiling)
  end
end
