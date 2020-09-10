# TODO(bkiahstroud): filename and location make sense?
module Hyrax
  module GroupsService
    class << self
      # TODO(bkiahstroud): add default descriptions
      def create_default_hyrax_groups
        default_group_names.each do |group_name|
          Hyrax::Group.find_or_create_by!(name: group_name)
        end
      end

      def destroy_default_hyrax_groups
        default_group_names.each do |group_name|
          Hyrax::Group.find_by!(name: group_name).destroy
        rescue ActiveRecord::RecordNotFound
          puts "Destroy failed! Could not find Hyrax::Group with the name '#{group_name}'!"
        end
      end

      # TODO(bkiahstroud): Grab list from Hyrax::RoleRegistry instead? See AdminSetCreateService
      def default_group_names
        %w[
          admin
          registered
          managing
        ]
      end
    end
  end
end
