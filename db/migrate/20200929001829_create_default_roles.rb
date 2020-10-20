class CreateDefaultRoles < ActiveRecord::Migration[5.1]
  def up
    RolesService.create_default_roles!
  end
end
