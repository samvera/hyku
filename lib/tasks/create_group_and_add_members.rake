# frozen_string_literal: true

# CREATE_GROUP_FOR=tenant rake hyku:cdl:create_group_and_add_members[id1.id2.id3]
# NOTE: we are using period separations because comma separates don't seem to work
# without the CREATE_GROUP_FOR env var, it will default to 'blc' tenant
namespace :hyku do
  namespace :cdl do
    desc 'Enqueue CreateGroupAndAddMembersJob for each provided ID'
    task :create_group_and_add_members, [:ids] => :environment do |_, args|
      tenant = ENV['CREATE_GROUPS_FOR'] || 'blc'
      switch!(tenant)

      ids = args[:ids].split('.').map(&:strip)
      ids.each do |id|
        CreateGroupAndAddMembersJob.perform_later(id)
      end
    end
  end
end
