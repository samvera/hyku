# frozen_string_literal: true

# Helpers for the digital collection theme's pages.
module DigitalCollectionHelper
  include ThemeColorHelper

  DC_STATUS_BASE = { danger: '#b4433c', success: '#3c763d' }.freeze
  DC_MAX_STEPS = 100
  DC_URL_OPTION_KEYS = %i[host protocol port domain subdomain tld_length script_name user password anchor trailing_slash only_path params].freeze
  DC_COLLECTION_SHOWN_ELSEWHERE = %i[title date_modified description total_items].freeze
  DC_WORK_SHOWN_ELSEWHERE = '.attribute-title, .attribute-description'
  DC_TALL_BANNER_RATIO = 4.0 / 3

  def dc_home
    theme_home(DigitalCollectionTheme::HomepagePresenter)
  end

  def dc_section_head(title, id:, eyebrow: nil, action: nil, &block)
    tag.div(class: 'dc-section-head') do
      safe_join([
        (tag.p(eyebrow, class: 'dc-section-eyebrow') if eyebrow),
        tag.h2(title, class: 'dc-section-title', id:),
        (capture(&block) if block),
        action
      ].compact)
    end
  end

  def dc_unread_count
    return 0 if admin_host? || !user_signed_in?

    UserMailbox.new(current_user).unread_count
  end

  def dc_account_links(unread)
    admin_host? ? dc_admin_host_links : dc_tenant_account_links(unread)
  end

  def dc_banner_src(collection_id)
    branding = dc_banner_branding(collection_id)
    branding ? dc_branding_path(branding) : banner_image
  end

  def dc_banner_branding(collection_id)
    dc_collection_branding(collection_id, 'banner').first
  end

  def dc_tall_banner?(branding)
    path = branding&.local_path
    return false if path.blank? || !File.exist?(path)

    Rails.cache.fetch(['dc-tall-banner', path, File.mtime(path).to_i]) do
      width, height = MiniMagick::Image.new(path).dimensions
      width.to_f / height < DC_TALL_BANNER_RATIO
    end
  rescue MiniMagick::Error
    false
  end

  def dc_collection_branding(collection_id, role)
    CollectionBrandingInfo.where(collection_id: collection_id.to_s, role:).select { |branding| branding.local_path.present? && File.exist?(branding.local_path) }
  end

  def dc_branding_path(branding)
    "/#{branding.local_path.split('/')[-4..].map { |segment| ERB::Util.url_encode(segment) }.join('/')}"
  end

  def dc_thumb_placeholder_class(document)
    path = document.try(:[], 'thumbnail_path_ss').to_s
    'dc-thumb-placeholder' if path.blank? || path.include?('/assets/')
  end

  def dc_logout_link
    return unless admin_host? || Flipflop.show_login_link? || current_ability.user_groups.include?('admin')

    [t('hyrax.toolbar.profile.logout'), main_app.destroy_user_session_path]
  end

  # rubocop:disable Rails/OutputSafety
  def dc_content_block(content_block, **options)
    return if content_block&.value.blank?

    fragment = Nokogiri::HTML::DocumentFragment.parse(content_block.value)
    fragment.css('h1').each { |heading| heading.name = 'h2' }
    tag.div(raw(fragment.to_html), **options)
  end

  def dc_hero_headline(content_block)
    fragment = Nokogiri::HTML::DocumentFragment.parse(content_block.value)
    headings = fragment.css('h1, h2, h3, h4, h5, h6')
    return tag.div(raw(fragment.to_html), class: 'dc-hero-headline', role: 'heading', aria: { level: 1 }) if headings.empty?

    headings.first.name = 'h1'
    headings.drop(1).each { |heading| heading.name = 'h2' if heading.name == 'h1' }
    tag.div(raw(fragment.to_html), class: 'dc-hero-headline')
  end
  # rubocop:enable Rails/OutputSafety

  def dc_badge(text, kind: nil, class_name: 'dc-badge')
    tag.span(text, class: token_list(class_name, "dc-badge-#{kind}" => kind))
  end

  def dc_mix(one, two, share_of_two)
    pairs = dc_channels(one).zip(dc_channels(two))
    dc_hex(pairs.map { |a, b| (a * (1 - share_of_two)) + (b * share_of_two) })
  end

  def dc_darken(hex, factor)
    dc_hex(dc_channels(hex).map { |channel| channel * factor })
  end

  def dc_darken_until(hex, surface, floor)
    color = hex
    DC_MAX_STEPS.times do
      break if theme_contrast(color, surface) >= floor
      color = dc_darken(color, 0.95)
    end
    color
  end

  def dc_lighten_until(hex, surface, floor)
    hue, saturation, lightness = dc_hsl(hex)
    0.upto(DC_MAX_STEPS) do |step|
      color = dc_from_hsl(hue, saturation, lightness + ((1 - lightness) * step / DC_MAX_STEPS.to_f))
      return color if theme_contrast(color, surface) >= floor
    end
    '#ffffff'
  end

  def dc_on_dark(hex, surface)
    dc_mix(hex, '#ffffff', (100 - theme_brand_mix_on(hex, surface)) / 100.0)
  end

  def dc_status_color(name, link, surface = '#ffffff')
    base = DC_STATUS_BASE.fetch(name)
    clash = name == :danger ? dc_reddish?(link) : dc_greenish?(link)
    share = clash ? 0 : [20, 15, 10, 5, 0].find { |percent| dc_hue_shift(dc_mix(base, link, percent / 100.0), base) <= 20 }
    dc_darken_until(dc_mix(base, link, share / 100.0), surface, 4.5)
  end

  def dc_visited_color(link, surface)
    color = dc_turn_hue(link, 56)
    color = dc_turn_hue(link, -56) if dc_reddish?(color) || dc_greenish?(color)
    dc_darken_until(color, surface, 4.5)
  end

  def dc_reddish?(hex)
    hue, saturation, = dc_hsl(hex)
    saturation > 0.1 && (hue >= 330 || hue <= 20)
  end

  def dc_greenish?(hex)
    hue, saturation, = dc_hsl(hex)
    saturation > 0.1 && (80..170).cover?(hue)
  end

  def dc_hue(hex)
    red, green, blue = dc_channels(hex).map { |channel| channel / 255.0 }
    high, low = [red, green, blue].minmax.reverse
    return 0.0 if high == low

    spread = high - low
    sector = case high
             when red then ((green - blue) / spread) % 6
             when green then ((blue - red) / spread) + 2
             else
               ((red - green) / spread) + 4
             end
    (sector * 60) % 360
  end

  def dc_hue_shift(one, two)
    distance = (dc_hue(one) - dc_hue(two)).abs
    [distance, 360 - distance].min
  end

  def dc_hsl(hex)
    red, green, blue = dc_channels(hex).map { |channel| channel / 255.0 }
    high, low = [red, green, blue].minmax.reverse
    lightness = (high + low) / 2
    saturation = high == low ? 0 : (high - low) / (1 - ((2 * lightness) - 1).abs)
    [dc_hue(hex), saturation, lightness]
  end

  def dc_from_hsl(hue, saturation, lightness)
    chroma = (1 - ((2 * lightness) - 1).abs) * saturation
    second = chroma * (1 - (((hue / 60.0) % 2) - 1).abs)
    offset = lightness - (chroma / 2)
    sectors = [[chroma, second, 0], [second, chroma, 0], [0, chroma, second],
               [0, second, chroma], [second, 0, chroma], [chroma, 0, second]]
    dc_hex(sectors[(hue % 360 / 60).floor].map { |value| (value + offset) * 255 })
  end

  def dc_turn_hue(hex, degrees)
    hue, saturation, lightness = dc_hsl(hex)
    dc_from_hsl((hue + degrees) % 360, saturation, lightness)
  end

  def dc_results_summary(total, query)
    formatted = number_with_delimiter(total)
    return t('digital_collection.search.results.summary', count: total, formatted:) if query.blank?

    t('digital_collection.search.results.summary_query', count: total, formatted:, query:)
  end

  def dc_works_count(count)
    t('digital_collection.homepage.browse.works_count', count:, formatted: number_with_delimiter(count))
  end

  def dc_results_range(response)
    return if response.total.zero?

    first = response.start + 1
    t('digital_collection.search.results.range_html',
      first: number_with_delimiter(first),
      last: number_with_delimiter(response.start + response.documents.size),
      total: number_with_delimiter(response.total))
  end

  def dc_applied_filter_count
    search_state.filters.sum { |filter| Array(filter.values).flatten.compact_blank.size }
  end

  def dc_advanced_match_op
    return unless params[:search_field].present? && params[:search_field] == blacklight_config.advanced_search&.[](:url_key)

    keys = blacklight_config.search_fields.values.reject { |field| field.include_in_advanced_search == false }.map(&:key)
    return if keys.count { |key| params[key].present? } < 2

    params[:op] == 'OR' ? :any : :all
  end

  def dc_keyword_chips(search_state)
    query = advanced_query
    return if query.nil? || query.keyword_queries.empty?

    chips = query.keyword_queries.map do |field, value|
      remove = search_action_path(remove_advanced_keyword_query(field, search_state.params).except(:controller, :action))
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        render_constraint_element(blacklight_config.search_fields[field].display_label('search'), value, remove:)
      end
    end
    safe_join(chips, "\n")
  end

  def dc_filter_chips(search_state)
    core = Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
      Blacklight::RenderConstraintsHelperBehavior.instance_method(:render_constraints_filters).bind_call(self, search_state)
    end
    safe_join([core, dc_advanced_range_chips(search_state)].compact, "\n")
  end

  def dc_feed_url(format)
    url_for(search_state.to_h.symbolize_keys.except(*DC_URL_OPTION_KEYS).merge(format:))
  end

  def dc_toolbar_path(anchor: nil, **changes)
    url_for(search_state.params_for_search(changes).except(:controller, :action).merge(only_path: true, anchor:).compact)
  end

  def dc_inline_markdown(text)
    html = markdown(text.to_s).to_s.strip
    sanitize(html.delete_prefix('<p>').delete_suffix('</p>'))
  end

  def dc_collection_type_label(collection_type)
    key = if collection_type.user_collection?
            'hyrax.collection_type.default_title'
          elsif collection_type.admin_set?
            'hyrax.collection_type.admin_set_title'
          end
    key && collection_type.title == I18n.t(key, locale: :en) ? t(key) : collection_type.title
  end

  def dc_collection_meta(presenter)
    updated = dc_long_date(presenter.modified_date)
    parts = [
      (t('digital_collection.collection.created_by', creator: dc_creator_names(presenter).first) if dc_creator_names(presenter).any?),
      tag.strong(t('digital_collection.collection.items', count: presenter.total_viewable_items)),
      (t('digital_collection.collection.updated', date: updated) if updated)
    ]
    safe_join(parts.compact, ' · ')
  end

  def dc_collection_metadata_rows(presenter)
    return dc_collection_term_rows(presenter) unless Hyrax.config.flexible?

    dc_collection_view_definitions(presenter).filter_map do |field, options|
      next if DC_COLLECTION_SHOWN_ELSEWHERE.include?(field.to_sym) || compound_card_field?(presenter, field)

      view_options = conform_options(field, options.deep_dup.with_indifferent_access)
      next unless field_visible?(view_options, presenter)

      dc_collection_metadata_row(presenter, conform_field(field, options), view_options)
    end
  end

  def dc_breadcrumb_trail(presenter)
    home = [t('hyrax.controls.home'), hyrax.root_path]
    case presenter
    when Hyrax::CollectionPresenter
      [home, [presenter.to_s, nil], dc_back_to_search_crumb].compact
    when Hyrax::FileSetPresenter
      work = presenter.parent
      [home, dc_collection_crumb(work), ([work.to_s, main_app.polymorphic_path(work)] if work)].compact
    else
      [home, dc_collection_crumb(presenter), [presenter.to_s, nil], dc_back_to_search_crumb].compact
    end
  end

  def dc_work_metadata_rows(presenter)
    fragment = Nokogiri::HTML::DocumentFragment.parse(dc_external_links_in_new_tab(render('hyrax/base/attribute_rows', presenter:)))
    fragment.css('dt').filter_map do |term|
      values = dc_row_values(term)
      next if values.any? { |value| value.at_css(dc_work_shown_elsewhere) }

      safe_join([term, *values].map { |node| node.to_html.html_safe }) # rubocop:disable Rails/OutputSafety
    end
  end

  def dc_work_collections(work)
    @dc_work_collections ||= {}
    @dc_work_collections[work.id] ||= work.member_of_collection_presenters.to_a
  end

  def dc_part_of_groups(presenter)
    collections = dc_work_collections(presenter).map { |collection| [collection.to_s, search_state.url_for_document(collection)] }
    parents = presenter.parent_works(current_user).map { |parent| [parent.title.first, parent_path(parent)] }
    admin_sets = presenter.editor? ? Array(presenter.admin_set).map { |name| [name, main_app.search_catalog_path(f: { admin_set_sim: [name] })] } : []
    { collection: collections, parent_work: parents, admin_set: admin_sets }.filter_map do |kind, links|
      [t("digital_collection.work.part_of.#{kind}", count: links.size), links] if links.any?
    end
  end

  def dc_file_detail_rows(presenter)
    [
      [:depositor, link_to_profile(presenter.depositor)],
      [:date_uploaded, dc_long_date(presenter.date_uploaded)],
      [:date_modified, dc_long_date(presenter.date_modified)],
      [:fixity, presenter.fixity_check_status],
      [:format, Array(presenter.mime_type).first],
      [:size, dc_file_size(presenter)],
      [:dimensions, dc_file_dimensions(presenter)]
    ].filter_map { |key, value| [t("digital_collection.file_set.details.#{key}"), value] if value.present? }
  end

  def dc_technical_label(presenter, term)
    t("digital_collection.file_set.technical.#{term}", default: presenter.label_for_term(term))
  end

  def dc_long_date(value)
    return if value.blank?

    date = value.is_a?(String) ? Date.parse(value) : value.to_date
    l(date, format: t('digital_collection.collection.date_format'))
  rescue Date::Error
    nil
  end

  def dc_card_meta(document, collection_label: false)
    parts = if document.collection?
              [(t('digital_collection.search.results.collection') if collection_label), dc_works_count_label(document)]
            else
              [dc_creator_names(document).first, dc_result_date(document)]
            end
    parts.compact_blank.join(' · ')
  end

  def dc_result_fields(document)
    return dc_profile_result_fields(document) if Hyrax.config.flexible?

    fields = document.collection? ? dc_collection_result_values(document) : dc_work_result_values(document)
    fields.filter_map do |key, value|
      [key, dc_result_row(t("digital_collection.search.results.fields.#{key}"), value)] if value.present?
    end
  end

  def dc_external_links_in_new_tab(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html.to_s)
    fragment.css('a[href]').each do |link|
      host = URI.parse(link['href']).host
      next if host.blank? || host == request.host

      link['target'] = '_blank'
      link['rel'] = (link['rel'].to_s.split + %w[noopener noreferrer]).uniq.join(' ')
      dc_move_external_icon_to_end(link)
    rescue URI::InvalidURIError
      next
    end
    fragment.to_html.html_safe # rubocop:disable Rails/OutputSafety
  end

  def dc_profile_view_definitions(document)
    model = dc_profile_model(document)
    @dc_profile_view_definitions ||= {}
    @dc_profile_view_definitions[[model, document.schema_version, document.contexts]] ||=
      Hyrax::Schema.m3_schema_loader.view_definitions_for(schema: model, version: document.schema_version, contexts: document.contexts)
  end

  def dc_creator_names(record)
    if record.is_a?(Blacklight::Document)
      dc_result_field_shown?(record, 'creator_tesim') ? theme_values(record, :creator).compact_blank : []
    else
      dc_profile_shows?(record, :creator) ? theme_values(record, :creator).compact_blank.uniq : []
    end
  end

  def dc_summary(record)
    return Array(record['description_tesim']).compact_blank if record.is_a?(Blacklight::Document)

    dc_profile_shows?(record, :description) ? Array(record.description).compact_blank : []
  end

  def dc_work_shown_elsewhere
    DC_WORK_SHOWN_ELSEWHERE
  end

  def dc_profile_shows?(presenter, field)
    return true unless Hyrax.config.flexible?

    options = dc_profile_view_definitions(presenter.solr_document)[field.to_sym]
    options.nil? || field_visible?(conform_options(field, options.deep_dup.with_indifferent_access), presenter)
  end

  def dc_profile_model(document)
    Valkyrie.config.resource_class_resolver.call(Array(document['has_model_ssim']).first || Hyrax.config.collection_model).to_s
  end

  private

  def dc_admin_host_links
    return [] unless can?(:manage, Account)

    [[t('hyku.proprietor.accounts.nav'), main_app.proprietor_accounts_path],
     [t('hyku.proprietor.users.nav'), main_app.proprietor_users_path]]
  end

  def dc_tenant_account_links(unread)
    links = [[t('hyrax.toolbar.dashboard.menu'), hyrax.dashboard_path],
             [t('digital_collection.chrome.notifications', count: unread), hyrax.notifications_path]]
    if (Flipflop.show_login_link? || current_ability.user_groups.include?('admin')) && Devise.mappings[:user]&.registerable?
      links << [t('hyku.toolbar.profile.edit_registration'), main_app.edit_user_registration_path]
    end
    links
  end

  def dc_channels(hex)
    hex.to_s.delete('#').scan(/../).map { |pair| pair.to_i(16) }
  end

  def dc_hex(channels)
    format('#%02x%02x%02x', *channels.map { |channel| channel.round.clamp(0, 255) })
  end

  def dc_advanced_range_chips(search_state)
    return unless respond_to?(:advanced_query) && advanced_query

    chips = advanced_query.filters.filter_map do |field, values|
      next unless blacklight_config.facet_fields[field]&.range

      remove = search_action_path(dc_without_advanced_filter(search_state, field).except(:controller, :action))
      Deprecation.silence(Blacklight::RenderConstraintsHelperBehavior) do
        render_constraint_element(facet_field_label(field), Array(values).join(', '), remove:)
      end
    end
    safe_join(chips, "\n") if chips.any?
  end

  def dc_without_advanced_filter(search_state, field)
    params = search_state.to_h.with_indifferent_access
    filters = params.fetch(:f_inclusive, {}).except(field)
    filters.empty? ? params.except(:f_inclusive) : params.merge(f_inclusive: filters)
  end

  def dc_collection_view_definitions(presenter)
    dc_profile_view_definitions(presenter.solr_document)
  end

  def dc_collection_metadata_row(presenter, field, view_options)
    if presenter.respond_to?(:compound_term?) && presenter.compound_term?(field)
      value = collection_metadata_value(presenter, field)
      safe_join([tag.dt(view_options[:label]), tag.dd(value)]) if value.present?
    elsif presenter.solr_document.respond_to?(field)
      presenter.attribute_to_html(field, view_options).presence
    end
  end

  def dc_collection_term_rows(presenter)
    (presenter.terms_with_values - DC_COLLECTION_SHOWN_ELSEWHERE).map do |field|
      safe_join([tag.dt(collection_metadata_label(presenter, field)), tag.dd(collection_metadata_value(presenter, field))])
    end
  end

  def dc_collection_crumb(work)
    collection = (dc_work_collections(work) if work.respond_to?(:member_of_collection_presenters))&.find { |parent| parent.is_a?(Hyrax::CollectionPresenter) }
    [collection.to_s, hyrax.collection_path(collection.id)] if collection
  end

  def dc_back_to_search_crumb
    referer = URI.parse(request.referer.to_s)
    return unless referer.host == request.host && referer.path.start_with?(URI.parse(main_app.search_catalog_path).path)

    [t('hyrax.bread_crumb.search_results'), request.referer]
  rescue URI::InvalidURIError
    nil
  end

  def dc_row_values(term)
    values = []
    node = term.next_element
    while node&.name == 'dd'
      values << node
      node = node.next_element
    end
    values
  end

  def dc_file_size(presenter)
    bytes = Array(presenter.file_size).first.to_i
    number_to_human_size(bytes) if bytes.positive?
  end

  def dc_file_dimensions(presenter)
    width = Array(presenter.width).first
    height = Array(presenter.height).first
    t('digital_collection.file_set.details.dimensions_value', width:, height:) if width.present? && height.present?
  end

  def dc_profile_result_fields(document)
    rows = document_presenter(document).fields_to_render.filter_map do |field_name, _config, presenter|
      next if field_name.to_s.start_with?('title_')

      value = presenter.render
      [dc_result_field_key(field_name), dc_result_row(index_field_label(document, field_name), markdown(value))] if value.present?
    end
    extra = document.collection? ? [:works, dc_works_count_label(document)] : [:part_of, dc_part_of_links(document)]
    extra.last.present? ? rows << [extra.first, dc_result_row(t("digital_collection.search.results.fields.#{extra.first}"), extra.last)] : rows
  end

  def dc_result_field_shown?(document, field_name)
    return true unless Hyrax.config.flexible?

    @dc_result_fields_shown ||= {}
    shown = @dc_result_fields_shown[document.id] ||= document_presenter(document).fields_to_render.map { |name, _config, _presenter| name.to_s }
    shown.include?(field_name)
  end

  def dc_result_field_key(field_name)
    field_name.to_s.sub(/_(tesim|ssim|sim|ssi|tesi|dtsi|isim|itsi)\z/, '').to_sym
  end

  def dc_result_row(label, value)
    safe_join([tag.dt(label), tag.dd(value)])
  end

  def dc_work_result_values(document)
    { creator: theme_values(document, :creator).join('; '),
      date: dc_result_date(document),
      part_of: dc_part_of_links(document),
      resource_type: theme_values(document, :resource_type).join(', '),
      description: theme_blurb(Array(document['description_tesim']).first, length: 300) }
  end

  def dc_collection_result_values(document)
    { description: theme_blurb(Array(document['description_tesim']).first, length: 300),
      works: dc_works_count_label(document) }
  end

  def dc_works_count_label(document)
    dc_works_count(Hyrax::CollectionPresenter.new(document, current_ability).total_viewable_works)
  end

  def dc_result_date(document)
    %w[date_created_tesim date_issued_tesim].each do |field_name|
      value = Array(document[field_name]).first
      return value if value.present? && dc_result_field_shown?(document, field_name)
    end
    nil
  end

  def dc_part_of_links(document)
    ids = Array(document['member_of_collection_ids_ssim'])
    links = Array(document['member_of_collections_ssim']).each_with_index.map do |name, index|
      ids[index] ? link_to(name, hyrax.collection_path(ids[index])) : name
    end
    safe_join(links, ', ')
  end

  def dc_move_external_icon_to_end(link)
    return if link.at_css('.dc-external-icon')

    dc_remove_leading_icon_before(link)
    dc_remove_leading_icon_inside(link)
    icon = link.document.create_element('span', class: 'fa fa-external-link dc-external-icon', 'aria-hidden': 'true')
    dc_last_word_with(link, icon)
    link.add_child(link.document.create_element('span', t('digital_collection.show.new_tab'), class: 'sr-only'))
  end

  def dc_last_word_with(link, icon)
    text = link.xpath('.//text()[normalize-space()]').last
    return link.add_child(icon) unless text

    before, last_word = text.content.match(/\A(.*?)(\S+)\s*\z/m)&.captures
    head, last_word = last_word.to_s.match(%r{\A(.*/)([^/]+/?)\z})&.captures || ['', last_word]
    before = "#{before}#{head}"
    keep = link.document.create_element('span', class: 'dc-external-end')
    keep.add_child(Nokogiri::XML::Text.new(last_word.to_s, link.document))
    keep.add_child(icon)
    text.content = before.to_s
    text.add_next_sibling(keep)
  end

  def dc_remove_leading_icon_before(link)
    node = link.previous_sibling
    node = node.previous_sibling while dc_blank_text?(node)
    return unless dc_external_icon?(node)

    node.next_sibling.remove while node.next_sibling != link
    node.remove
  end

  def dc_remove_leading_icon_inside(link)
    node = link.children.first
    node = node.next_sibling while dc_blank_text?(node)
    return unless dc_external_icon?(node)

    node.previous_sibling.remove while node.previous_sibling
    following = node.next_sibling
    node.remove
    following.content = following.content.sub(/\A[\s\u00A0]+/, '') if following&.text?
  end

  def dc_blank_text?(node)
    node&.text? && node.content.delete("\u00A0").strip.empty?
  end

  def dc_external_icon?(node)
    node&.element? && node['class'].to_s.split.include?('fa-external-link')
  end
end
