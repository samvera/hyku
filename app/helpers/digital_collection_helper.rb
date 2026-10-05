# frozen_string_literal: true

# Helpers for the digital collection theme's home and show pages.
module DigitalCollectionHelper
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
end
