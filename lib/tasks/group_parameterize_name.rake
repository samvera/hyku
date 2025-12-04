# frozen_string_literal: true

namespace :hyku do
  desc "Update group name to be parameterized"
  task update_hyrax_group_names: :environment do
    Account.find_each do |account|
      puts "Running update group names task within '#{account.cname}' tenant"
      AccountElevator.switch!(account.cname)
      groups = Hyrax::Group.where(humanized_name: nil)
      puts "updating the group humanized name"

      ActiveRecord::Base.transaction do
        groups.each do |group|
          group.update!(humanized_name: group.name)
          print "."
        end
      end
      puts " Missing humanized names are added"

      ActiveRecord::Base.transaction do
        groups.each do |group|
          parameterized_name = group.name.tr(" ", "_").downcase
          group.update!(name: parameterized_name)
          print "."
        end
      end
      puts " All group names are parameterized"
    end
  end
end
