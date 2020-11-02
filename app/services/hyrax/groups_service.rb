# frozen_string_literal: true
# TODO(bkiahstroud): filename and location make sense?
module Hyrax
  module GroupsService
    ##
    # NOTE(bkiahstroud): DO NOT CHANGE THE NAMES OF THESE GROUPS!
    # They are required to exist for permissions to work properly.
    # TODO(bkiahstroud): Grab list from Hyrax::RoleRegistry instead? See AdminSetCreateService
    ALL_DEFAULT_GROUPS = [
      'admin',
      'registered',
      'public',
      'managing'
    ].freeze

    class << self
      # TODO(bkiahstroud): add default descriptions using i18n
      def create_default_hyrax_groups!
        ALL_DEFAULT_GROUPS.each do |group_name|
          Hyrax::Group.find_or_create_by!(name: group_name)
        end
      end
    end
  end
end
