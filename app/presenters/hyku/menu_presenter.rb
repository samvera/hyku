# frozen_string_literal: true

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
        can?(:manage, Hyrax::Group)
    end

    # Returns true if we ought to show the user Admin-only areas of the menu
    def show_admin_menu_items?
      can?(:read, :admin_dashboard)
    end

    def show_task?
      can?(:review, :submissions) ||
        can?(:read, User) ||
        can?(:read, Hyrax::Group) ||
        can?(:read, :admin_dashboard)
    end

    # Draw a collaspable menu section. The passed block should contain <li> items.
    # Override Hyrax v5.0.0rc2 to pass in title attribute
    # rubocop:disable Metrics/ParameterLists
    def collapsable_section(text, id:, icon_class:, title:, open:, &block)
      # rubocop:enable Metrics/ParameterLists
      CollapsableSectionPresenter.new(view_context:,
                                      text:,
                                      id:,
                                      icon_class:,
                                      title:,
                                      open:).render(&block)
    end
  end
end
