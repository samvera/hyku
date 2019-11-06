# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  module Actors
    class OerActor < Hyrax::Actors::BaseActor
      
      def add_custom_relations(env)
        attributes_collection = env.attributes.delete(:related_members_attributes)
        Rails.logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++")
        Rails.logger.info(attributes_collection)
        Rails.logger.info("++++++++++++++++++++++++++++++++++++++++++++++++++++++")
        # env.attributes.add(:previous_version)
        return env
        
      end

      def apply_save_data_to_curation_concern(env)
        env= add_custom_relations(env)
        super
      end

    end
  end
end
