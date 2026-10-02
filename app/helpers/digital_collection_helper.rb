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

  def dc_logout_link
    return unless admin_host? || Flipflop.show_login_link? || current_ability.user_groups.include?('admin')

    [t('hyrax.toolbar.profile.logout'), main_app.destroy_user_session_path]
  end

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
