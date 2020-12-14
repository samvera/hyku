class MakeSureUsersHaveGroups < ActiveRecord::Migration[5.2]
  def change
    Account.all.each do |account|
      AccountElevator.switch!(account.cname)
      User.find_each do |u|
        u.add_default_group_memberships!
      end
    end
  end
end
