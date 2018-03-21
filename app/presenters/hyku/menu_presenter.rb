module Hyku
  # view-model for the admin menu
  class MenuPresenter < Hyrax::MenuPresenter
    # Returns true if the current controller happens to be one of the controllers that deals
    # with settings.  This is used to keep the parent section on the sidebar open.
    def settings_section?
      %w[appearances content_blocks labels features pages].include?(controller_name)
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with roles and permissions.  This is used to keep the parent section on the sidebar open.
    def roles_and_permissions_section?
      # we're using a case here because we need to differentiate UsersControllers
      # in different namespaces (Hyrax & Admin)
      case controller
      when Hyrax::Admin::UsersController, ::Admin::GroupsController
        true
      else
        false
      end
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with repository activity  This is used to keep the parent section on the sidebar open.
    def repository_activity_section?
      %w[admin dashboard status].include?(controller_name)
    end

    # Returns true if we ought to show the user the 'Configuration' section
    # of the menu
    def show_configuration?
      super ||
        can?(:manage, Site) ||
        can?(:manage, User) ||
        can?(:manage, Hyku::Group)
    end

    # Returns true if we ought to show the user Admin-only areas of the menu
    def show_admin_menu_items?
      can?(:read, :admin_dashboard)
    end
  end
end
