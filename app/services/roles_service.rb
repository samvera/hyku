# frozen_string_literal: true

class RolesService # rubocop:disable Metrics/ClassLength
  ADMIN_ROLE = 'admin'

  COLLECTION_ROLES = %w[
    collection_manager
    collection_editor
    collection_reader
  ].freeze

  USER_ROLES = %w[
    user_manager
    user_reader
  ].freeze

  WORK_ROLES = %w[
    work_editor
    work_depositor
  ].freeze

  DEFAULT_ROLES = [ADMIN_ROLE] + COLLECTION_ROLES + USER_ROLES + WORK_ROLES

  DEFAULT_HYRAX_GROUPS_WITH_ATTRIBUTES = {
    # This Hyrax::Group is required to exist for permissions to work properly
    "#{::Ability.admin_group_name}": {
      humanized_name: I18n.t('hyku.admin.groups.humanized_name.admin'),
      description: I18n.t('hyku.admin.groups.description.admin')
    }.freeze,
    # This Hyrax::Group is required to exist for permissions to work properly
    "#{::Ability.registered_group_name}": {
      humanized_name: I18n.t('hyku.admin.groups.humanized_name.registered'),
      description: I18n.t('hyku.admin.groups.description.registered')
    }.freeze,
    editors: {
      humanized_name: 'Editors',
      description: I18n.t('hyku.admin.groups.description.editors')
    }.freeze,
    depositors: {
      humanized_name: 'Depositors',
      description: I18n.t('hyku.admin.groups.description.depositors')
    }.freeze
  }.freeze

  DEFAULT_ROLES_FOR_DEFAULT_HYRAX_GROUPS = {
    "#{::Ability.admin_group_name}": {
      roles: %i[admin].freeze
    }.freeze,
    "#{::Ability.registered_group_name}": {
      roles: [].freeze
    }.freeze,
    editors: {
      roles: %i[work_editor collection_editor user_reader].freeze
    }.freeze,
    depositors: {
      roles: %i[work_depositor].freeze
    }.freeze
  }.freeze

  class << self
    def find_or_create_site_role!(role_name:)
      Role.find_or_create_by!(
        name: role_name,
        resource_id: Site.instance.id,
        resource_type: 'Site'
      )
    end

    def create_default_roles!
      # Prevent Roles from being created in the public schema
      return '`AccountElevator.switch!` into an Account before creating default Roles' if Site.instance.is_a?(NilSite)

      DEFAULT_ROLES.each do |role_name|
        find_or_create_site_role!(role_name:)
      end
    end

    def create_default_hyrax_groups_with_roles!
      # Prevent Hyrax::Groups from being created in the public schema
      return '`AccountElevator.switch!` into an Account before creating default Hyrax::Groups' if Site.instance.is_a?(NilSite)

      default_hyrax_groups_with_roles =
        DEFAULT_HYRAX_GROUPS_WITH_ATTRIBUTES.deep_merge(DEFAULT_ROLES_FOR_DEFAULT_HYRAX_GROUPS)

      default_hyrax_groups_with_roles.each do |group_name, group_attrs|
        group_roles = group_attrs.delete(:roles)
        group = Hyrax::Group.find_or_create_by!(name: group_name)
        group.update(group_attrs)

        group_roles.each do |role_name|
          next if role_name.blank?

          group.roles |= [find_or_create_site_role!(role_name:)]
        end
      end
    end

    # Because each collection role has some level of access to every Collection within a tenant,
    # creating a Hyrax::PermissionTemplateAccess record (combined with Ability#user_groups)
    # means all Collections will show up in Blacklight / Solr queries.
    # rubocop:disable Metrics/MethodLength
    def create_collection_accesses!
      CreateCollectionAccessesJob.perform_now
    end
    # rubocop:enable Metrics/MethodLength

    # Creating a Hyrax::PermissionTemplateAccess record (combined with Ability#user_groups)
    # will allow Works in all AdminSets to show up in Blacklight / Solr queries.
    # rubocop:disable Metrics/MethodLength
    def create_admin_set_accesses!
      CreateAdminSetAccessesJob.perform_now
    end
    # rubocop:enable Metrics/MethodLength

    # Because some of the collection roles have access to every Collection within a tenant, create a
    # Hyrax::CollectionTypeParticipant record for them on every Hyrax::CollectionType (except the AdminSet)
    def create_collection_type_participants!
      CreateCollectionTypeParticipantsJob.perform_now
    end

    # Because the collection roles are used to explicitly grant Collection creation permissions,
    # provide a way to easily remove that access from all registered users. Participants can
    # still be added / removed on an individual Hyrax::CollectionType basis.
    #
    # NOTE: This is not technically necessary for collection roles to function properly. However,
    # without it, collection readers will be allowed to create Collections whose Hyrax::CollectionType
    # has this Hyrax::CollectionTypeParticipant.
    def destroy_registered_group_collection_type_participants!
      Hyrax::CollectionTypeParticipant.where(
        agent_type: 'group',
        agent_id: ::Ability.registered_group_name,
        access: 'create'
      ).map(&:destroy)
    end

    # Ensure users with the admin role are given memberships to their default groups (registered and admin).
    # This method is primarily intended to be used for migrating existing Hyku applications to use the
    # Groups with Roles feature; it should not be necessary to run more than once. For example, when
    # creating a new tenant, admins should automatically be added to the admin group.
    #
    # @see Account#add_initial_users
    # @see https://github.com/samvera/hyku/wiki/Groups-with-Roles-Feature#setup-an-existing-application-to-use-groups-with-roles
    def create_admin_group_memberships!
      User.select { |user| user.has_role?('admin', Site.instance) }.each do |admin|
        Hyrax::Group.find_or_create_by!(name: Ability.registered_group_name).add_members_by_id(admin.id)
        Hyrax::Group.find_or_create_by!(name: Ability.admin_group_name).add_members_by_id(admin.id)
      end
    end

    # Permissions to deposit Works are controlled by Workflow Roles on individual AdminSets. In order for Hyrax::Group
    # and User records who have either the :work_editor or :work_depositor Rolify Role to have the correct permissions
    # for Works, we grant them Workflow Roles for all AdminSets.
    #
    # NOTE: All AdminSets must have a permission template or this will fail. Run #create_admin_set_accesses first.
    def grant_workflow_roles_for_all_admin_sets!
      GrantWorkflowRolesForAllAdminSetsJob.perform_now
    end

    # This method is inspired by the devise_guests:delete_old_guest_users rake task in the devise-guests gem:
    # https://github.com/cbeer/devise-guests/blob/master/lib/railties/devise_guests.rake
    def prune_stale_guest_users
      stale_guest_users = User.unscoped.where(
        'guest = ? and updated_at < ?',
        true,
        7.days.ago
      )
      progress = ProgressBar.create(total: stale_guest_users.count)

      stale_guest_users.find_each do |u|
        progress.increment
        u.destroy
      end
    end

    # rubocop:disable Metrics/MethodLength
    def seed_superadmin!
      # rubocop:disable Rails/UnknownEnv
      return 'Seed data should not be used in the production environment' if Rails.env.production? || Rails.env.staging?
      # rubocop:enable Rails/UnknownEnv
      user = User.where(email: 'admin@example.com').first_or_initialize do |u|
        if u.new_record?
          u.password = 'testing123'
          u.display_name = 'Admin'
          u.save!
        end
        u
      end

      user.roles << Role.find_or_create_by!(name: 'superadmin') unless user.has_role?('superadmin')

      Account.find_each do |account|
        AccountElevator.switch!(account.cname)

        user.add_default_group_membership!
        Hyrax::Group.find_or_create_by!(name: Ability.admin_group_name).add_members_by_id(user.id)
      end

      user
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def seed_qa_users!
      # rubocop:disable Rails/UnknownEnv
      return 'Seed data should not be used in the production environment' if Rails.env.production? || Rails.env.staging?
      # rubocop:disable Rails/UnknownEnv
      ActiveRecord::Base.transaction do
        DEFAULT_ROLES.each do |role_name|
          user = User.where(email: "#{role_name}@example.com").first_or_initialize do |u|
            if u.new_record?
              u.password = 'testing123'
              u.display_name = role_name.titleize
              u.save!
            end
            u
          end

          Account.find_each do |account|
            AccountElevator.switch!(account.cname)

            unless user.has_role?(role_name, Site.instance)
              user.add_default_group_membership!
              user.roles << find_or_create_site_role!(role_name:)
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end

  class GrantWorkflowRolesForAllAdminSetsJob < Hyrax::ApplicationJob
    def perform
      Hyrax.query_service.find_all_of_model(model: Hyrax.config.admin_set_class).each do |admin_set|
        Hyrax::Workflow::PermissionGrantor
          .grant_default_workflow_roles!(permission_template: admin_set.permission_template)
      end
    end
  end

  class CreateCollectionAccessesJob < Hyrax::ApplicationJob
    # rubocop:disable Metrics/MethodLength
    def self.create_access_for(collection:)
      # TODO: Extract a class attribute for configuration of these values
      pt = Hyrax::PermissionTemplate.find_or_create_by!(source_id: collection.id)
      original_access_grants_count = pt.access_grants.count

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::MANAGE,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: Ability.admin_group_name
      )

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::MANAGE,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_manager'
      )

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::VIEW,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_editor'
      )

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::VIEW,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'collection_reader'
      )

      pt.reset_access_controls_for(collection:) if pt.access_grants.count != original_access_grants_count
    end
    # rubocop:enable Metrics/MethodLength

    def perform
      Hyrax.query_service.find_all_of_model(model: Hyrax.config.collection_class).each do |c|
        self.class.create_access_for(collection: c)
      end
    end
  end

  class CreateAdminSetAccessesJob < Hyrax::ApplicationJob
    # rubocop:disable Metrics/MethodLength
    def self.create_access_for(admin_set:)
      # TODO: Extract a class attribute for configuration of these values
      pt = Hyrax::PermissionTemplate.find_or_create_by!(source_id: admin_set.id)
      original_access_grants_count = pt.access_grants.count

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::MANAGE,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: Ability.admin_group_name
      )

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::DEPOSIT,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'work_depositor'
      )

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::DEPOSIT,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'work_editor'
      )

      pt.access_grants.find_or_create_by!(
        access: Hyrax::PermissionTemplateAccess::VIEW,
        agent_type: Hyrax::PermissionTemplateAccess::GROUP,
        agent_id: 'work_editor'
      )

      pt.reset_access_controls_for(collection: admin_set) if pt.access_grants.count != original_access_grants_count
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def perform
      models = [Hyrax.config.admin_set_class].uniq

      models.each do |admin_set_model|
        Hyrax.query_service.find_all_of_model(model: admin_set_model).each do |admin_set|
          self.class.create_access_for(admin_set:)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end

  class CreateCollectionTypeParticipantsJob < Hyrax::ApplicationJob
    def perform
      Hyrax::CollectionType.find_each do |ct|
        next if ct.admin_set?

        # The :collection_manager role will automatically get a Hyrax::PermissionTemplateAccess
        # record when a Collection is created, giving them manage access to that Collection.
        ct.collection_type_participants.find_or_create_by!(
          access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS,
          agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
          agent_id: 'collection_manager'
        )

        # The :collection_editor role will automatically get a Hyrax::PermissionTemplateAccess
        # record when a Collection is created, giving them create access to that Collection.
        ct.collection_type_participants.find_or_create_by!(
          access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS,
          agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
          agent_id: 'collection_editor'
        )
      end
    end
  end

  class CleanReviewSubmissionsPageJob < Hyrax::ApplicationJob
    def perform
      Sipity::Entity.find_each do |entity|
        entity.proxy_for
      rescue Ldp::Gone, Ldp::NotFound, Valkyrie::Persistence::ObjectNotFoundError
        entity.destroy
      end
    end
  end

  def self.valid_jobs
    ActiveSupport::HashWithIndifferentAccess.new(
      create_collection_accesses: CreateCollectionAccessesJob,
      create_admin_set_accesses: CreateAdminSetAccessesJob,
      create_collection_type_participants: CreateCollectionTypeParticipantsJob,
      grant_workflow_roles_for_all_admin_sets: GrantWorkflowRolesForAllAdminSetsJob,
      clean_review_submissions_page: CleanReviewSubmissionsPageJob
    )
  end
end
