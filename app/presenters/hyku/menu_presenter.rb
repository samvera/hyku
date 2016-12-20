module Hyku
  # view-model for the admin menu
  class MenuPresenter
    def initialize(view_context)
      @view_context = view_context
    end

    attr_reader :view_context

    delegate :controller, :controller_name, :content_tag, :current_page?, :link_to,
             to: :view_context

    # Returns true if the current controller happens to be one of the controllers that deals
    # with settings.  This is used to keep the parent section on the sidebar open.
    def settings_section?
      %w(appearances content_blocks labels features).include?(controller_name)
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with workflow.  This is used to keep the parent section on the sidebar open.
    def workflows_section?
      %w(admin workflow_roles).include?(controller_name)
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with roles and permissions.  This is used to keep the parent section on the sidebar open.
    def roles_and_permissions_section?
      # we're using a case here because we need to differentiate UsersControllers
      # in different namespaces (Hyrax & Admin)
      case controller
      when Admin::UsersController, RolesController
        true
      else
        false
      end
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with repository activity  This is used to keep the parent section on the sidebar open.
    def repository_activity_section?
      %w(admin status).include?(controller_name)
    end

    # Returns true if the current controller happens to be one of the controllers that deals
    # with user activity  This is used to keep the parent section on the sidebar open.
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

    def nav_link(href, **link_options)
      content_tag(:li, class: ('active' if current_page?(href))) do
        link_to(href, link_options) do
          yield
        end
      end
    end
  end
end
