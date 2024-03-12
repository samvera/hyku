class MakeSureUsersHaveGroups < ActiveRecord::Migration[5.2]
  def change
    User.find_each do |u|
      u.add_default_group_memberships!
    end
  end
end
