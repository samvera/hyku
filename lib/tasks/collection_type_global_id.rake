# frozen_string_literal: true

namespace :hyrax do
  namespace :collections do
    desc 'Update CollectionType global id references for Hyrax 3.0.0'
    # NOTE: the definition of collection_type_gid= changed in Hyrax 5.0. This
    # rake task is known to work for updates to versions prior to Hyrax 5.
    # Use for later versions is unknown.
    task update_collection_type_global_ids: :environment do
      Account.find_each do |account|
        next if account.search_only.eql? true

        puts "🎪🎪 Updating collection -> collection type GlobalId references within '#{account.name}' tenant"
        AccountElevator.switch!(account.cname)

        count = 0

        Collection.find_each do |collection|
          next if collection.collection_type_gid == collection.collection_type.to_global_id.to_s

          collection.public_send(:collection_type_gid=, collection.collection_type.to_global_id, force: true)

          collection.save &&
            count += 1
        end

        puts "💯💯 Updated #{count} collections within '#{account.name}' tenant"
      end
    end
  end
end
