# frozen_string_literal: true

namespace :hyku do
  namespace :superadmin do
    desc 'Grant the superadmin role to specified users'
    task 'grant', [:user_list] => [:environment] do |_cmd, args|
      raise ArgumentError, 'A list of users is required: `rake superadmin:grant[user1,user2,...]`' unless args.user_list
      args.to_a.each do |u|
        user = User.find_by_user_key(u)
        if user
          user.add_role(:superadmin)
        else
          warn("Could not find user #{u}")
        end
      end
    end
  end
end
