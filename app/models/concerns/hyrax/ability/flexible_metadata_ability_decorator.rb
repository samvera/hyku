# frozen_string_literal: true

# OVERRIDE Hyrax v5.2.0 Alter abilities for search tenant
module Hyrax
  module Ability
    module FlexibleMetadataAbilityDecorator
      def flexible_metadata_abilities
        if Site.account&.search_only?
          cannot :manage, Hyrax::FlexibleSchema
        else
          super
        end
      end
    end
  end
end

Hyrax::Ability::FlexibleMetadataAbility.prepend Hyrax::Ability::FlexibleMetadataAbilityDecorator
