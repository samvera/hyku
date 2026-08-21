# frozen_string_literal: true

module Hyrax
  # view-model for the admin menu
  #
  # NOTE: Hyku::MenuPresenter subclasses Hyrax::MenuPresenter and redefines most of
  # these methods. A subclass wins over a module prepended to its parent, so within
  # Hyku this module is shadowed and only the subclass is consulted — Hyku's dashboard
  # sidebar instantiates that subclass. This module still applies to anything
  # instantiating Hyrax::MenuPresenter itself, such as a knapsack.
  #
  # Change a method here and the same change is needed in Hyku::MenuPresenter, or the
  # two disagree and the Hyku one is what users get.
  module MenuPresenterDecorator
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
        can?(:read, :admin_dashboard) ||
        can?(:view, :controlled_vocabularies)
    end
  end
end

Hyrax::MenuPresenter.section_controller_names = %w[appearances content_blocks labels features pages]
Hyrax::MenuPresenter.prepend(Hyrax::MenuPresenterDecorator)
