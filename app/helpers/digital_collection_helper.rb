# frozen_string_literal: true

# Helpers for the digital collection theme's home and show pages.
module DigitalCollectionHelper
  include ThemeColorHelper

  DC_STATUS_BASE = { danger: '#b4433c', success: '#3c763d' }.freeze
  DC_MAX_STEPS = 100

  def dc_home
    theme_home(DigitalCollection::HomepagePresenter)
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
    branding = CollectionBrandingInfo.find_by(collection_id: collection_id.to_s, role: 'banner')
    return banner_image unless branding&.local_path.present? && File.exist?(branding.local_path)

    "/#{branding.local_path.split('/')[-4..].join('/')}"
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
end
