namespace :hyku do
  namespace :seed do
    desc 'Create a User with the superadmin Role'
    task superadmin: :environment do
      return 'Seed data should not be used in the production environment' if Rails.env == 'production'

      user = User.where(email: 'admin@example.com').first_or_initialize do |u|
        if u.new_record?
          u.password = 'testing123'
          u.save!
        end
        u
      end

      unless user.has_role?('superadmin')
        user.roles << Role.find_or_create_by!(name: 'superadmin')
      end

      Account.find_each do |account|
        AccountElevator.switch!(account.cname)

        user.add_default_group_memberships!
      end

      user
    end

    desc 'Create QA users with roles'
    task qa_users: :environment do
      return 'Seed data should not be used in the production environment' if Rails.env == 'production'

      ActiveRecord::Base.transaction do
        RolesService::ALL_DEFAULT_ROLES.each do |role_name|
          user = User.where(email: "#{role_name}@example.com").first_or_initialize do |u|
            if u.new_record?
              u.password = 'testing123'
              u.save!
            end
            u
          end

          Account.find_each do |account|
            AccountElevator.switch!(account.cname)

            unless user.has_role?(role_name, Site.instance)
              user.add_default_group_memberships!
              user.roles << Role.find_by!(name: role_name, resource_id: Site.instance.id, resource_type: 'Site')
            end
          rescue ActiveRecord::RecordNotFound => e
            puts "#{e.message}. Make sure the default Roles exist (RolesService.create_default_roles!) " \
                 'before seeding the QA Users'
            raise e
          end

          puts "Email: #{user.email}\nRoles: #{user.roles.map(&:name)}\n\n"; nil
        end
      end
    end
  end
end
