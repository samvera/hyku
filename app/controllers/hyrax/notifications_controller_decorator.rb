# frozen_string_literal: true

# OVERRIDE: Hyrax v5.2.0 to mark all unread messages as read when the user visits the notifications dashboard

module Hyrax
  module NotificationsControllerDecorator
    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.notifications'), hyrax.notifications_path
      @messages = user_mailbox.inbox

      # OVERRIDE: Mark all unread messages as read when user visits the notifications dashboard
      mark_messages_as_read

      # Update the notifications now that there are zero unread
      StreamNotificationsJob.perform_later(current_user)
    end

    private

    def mark_messages_as_read
      Mailboxer::Receipt.where(
        receiver: current_user,
        is_read: false,
        deleted: false
      ).find_each do |receipt|
        receipt.update(is_read: true)
      end
    end
  end
end

Hyrax::NotificationsController.prepend Hyrax::NotificationsControllerDecorator
