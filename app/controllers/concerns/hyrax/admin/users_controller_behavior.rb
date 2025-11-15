# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Authorize User access and set up roles dropdown
module Hyrax
  module Admin
    module UsersControllerBehavior
      extend ActiveSupport::Concern
      include Blacklight::SearchContext
      included do
        # OVERRIDE Hyrax v5.0.0rc2 Replace :ensure_admin! with :ensure_access! to leverage User abilities.
        # @see app/models/concerns/hyrax/ability/user_ability.rb
        before_action :ensure_access!
        with_themed_layout 'dashboard'
      end

      # Display admin menu list of users
      def index
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.users.index.title'), hyrax.admin_users_path
        @presenter = Hyrax::Admin::UsersPresenter.new
        # OVERRIDE Hyrax v5.0.0rc2 Sets up a list of role names to be used by a dropdown input that
        # allows users to be invited with a specific role.
        @invite_roles_options = if current_ability.admin?
                                  ::RolesService::DEFAULT_ROLES
                                else
                                  ::RolesService::DEFAULT_ROLES - [::RolesService::ADMIN_ROLE]
                                end
      end

      private

      # OVERRIDE Hyrax v5.0.0rc2 Replace :ensure_admin! with :ensure_access! to leverage User abilities.
      # @see app/models/concerns/hyrax/ability/user_ability.rb
      def ensure_access!
        authorize! :read, ::User
      end
    end
  end
end
