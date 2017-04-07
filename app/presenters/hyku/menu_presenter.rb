module Hyku
  # view-model for the admin menu
  class MenuPresenter < Hyrax::MenuPresenter
    # Returns true if the current controller happens to be one of the controllers that deals
    # with settings.  This is used to keep the parent section on the sidebar open.
    def settings_section?
      %w(appearances content_blocks labels features).include?(controller_name)
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with roles and permissions.  This is used to keep the parent section on the sidebar open.
    def roles_and_permissions_section?
      # we're using a case here because we need to differentiate UsersControllers
      # in different namespaces (Hyrax & Admin)
      case controller
      when ::Admin::UsersController, ::Admin::GroupsController
        true
      else
        false
      end
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with repository activity. This is used to keep the parent section on the sidebar open.
    def repository_activity_section?
      %w(admin dashboard status).include?(controller_name)
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with user activity. This is used to keep the parent section on the sidebar open.
    def user_activity_section?
      # we're using a case here because we need to differentiate UsersControllers
      # in different namespaces (Hyrax & Admin)
      case controller
      when Hyrax::UsersController, Hyrax::MailboxController, Hyrax::TransfersController
        true
      else
        false
      end
    end
  end
end
