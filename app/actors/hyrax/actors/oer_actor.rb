# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  module Actors
    class OerActor < Hyrax::Actors::BaseActor

      def create(env)
        attributes_collection = env.attributes.delete(:related_members_attributes)
        env = add_custom_relations(env, attributes_collection)
        super
      end
        
      def update(env)
        attributes_collection = env.attributes.delete(:related_members_attributes)
        env = add_custom_relations(env, attributes_collection)
        super
      end

      private
        def add_custom_relations(env, attributes_collection)
          return env unless attributes_collection
          # before {"0"=>{"id"=>"6e9740ab-fc9c-403f-9e01-9c06c85148ee", "_destroy"=>"false"}, "1"=>{"id"=>"9abb566c-4873-4565-b02b-b32c7dd46fc8", "_destroy"=>"false"}}
          # after  [{"id"=>"6e9740ab-fc9c-403f-9e01-9c06c85148ee", "_destroy"=>"false"}, {"id"=>"9abb566c-4873-4565-b02b-b32c7dd46fc8", "_destroy"=>"false"}]
          attributes = attributes_collection&.sort_by { |i, _| i.to_i }&.map { |_, attributes| attributes }
          # checking for existing works to avoid rewriting/loading works that are already attached
          existing_previous_works = env.curation_concern.previous_version
          attributes&.each do |attributes|

            next if attributes['id'].blank?
            if existing_previous_works&.include?(attributes['id'])
              env = remove(env, attributes['id']) if
                ActiveModel::Type::Boolean.new.cast(attributes['_destroy'])
            else
              env = add(env, attributes['id'])
            end
          end
          env
        end

        def add(env, id)
          env.curation_concern.previous_version = (env.curation_concern.previous_version.to_a << id)
          env.curation_concern.save
          return env
        end

        def remove(env, id)
          env.curation_concern.previous_version = (env.curation_concern.previous_version.to_a - [id])
          env.curation_concern.save
          return env
        end

      
    end
  end
end
