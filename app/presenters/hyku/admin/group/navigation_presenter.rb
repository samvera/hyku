# frozen_string_literal: true

module Hyku
  module Admin
    module Group
      ##
      # A class to help orchestrate the tabs for the given group.
      class NavigationPresenter
        def initialize(params:)
          @params = params
          @group_id = params.fetch(group_id_key)
        end

        def tabs
          [
            edit_tab,
            members_tab,
            roles_tab,
            remove_tab
          ]
        end

        private

        attr_reader :group_id, :params

        def edit_tab
          Tab.new(
            name: I18n.t('hyku.admin.groups.nav.attributes'),
            controller: 'admin/groups',
            action: 'edit',
            path: Rails.application.routes.url_helpers.edit_admin_group_path(group_id, locale: I18n.locale),
            context: params
          )
        end

        def members_tab
          Tab.new(
            name: I18n.t('hyku.admin.groups.nav.members'),
            controller: 'admin/group_users',
            action: 'index',
            path: Rails.application.routes.url_helpers.admin_group_users_path(group_id, locale: I18n.locale),
            context: params
          )
        end

        def roles_tab
          Tab.new(
            name: I18n.t('hyku.admin.groups.nav.roles'),
            controller: 'admin/group_roles',
            action: 'index',
            path: Rails.application.routes.url_helpers.admin_group_roles_path(group_id, locale: I18n.locale),
            context: params
          )
        end

        def remove_tab
          Tab.new(
            name: I18n.t('hyku.admin.groups.nav.delete'),
            controller: 'admin/groups',
            action: 'remove',
            path: Rails.application.routes.url_helpers.remove_admin_group_path(group_id, locale: I18n.locale),
            context: params
          )
        end

        def group_id_key
          return :id if params.key?(:id)
          return :group_id if params.key?(:group_id)
          :key_not_found
        end

        class Tab
          ACTIVE_CSS_CLASS = 'active'

          attr_reader :name, :path, :action

          def initialize(name:, controller:, action:, path:, context:)
            @name = name
            @controller = controller
            @action = action
            @path = path
            @context = context
          end

          def css_class
            return ACTIVE_CSS_CLASS if context.fetch(:controller) == controller && context.fetch(:action) == action
            ''
          end

          private

          attr_reader :controller, :context
        end
      end
    end
  end
end
