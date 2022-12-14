# frozen_string_literal: true

module Hyrax
  module Ability
    module UserAbility
      def user_roles
        # Can create, read, and edit/update destroy all Users, cannot become a User
        if user_manager?
          can %i[create read update edit remove], User
          can %i[create read update edit remove destroy], Hyrax::Group
        # Can read all Users and Groups
        elsif user_reader?
          can %i[read], User
          can :read, Hyrax::Group
        end
      end
    end
  end
end
