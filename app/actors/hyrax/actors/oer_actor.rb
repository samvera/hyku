# Generated via
#  `rails generate hyrax:work Oer`
module Hyrax
  module Actors
    class OerActor < Hyrax::Actors::BaseActor

      def create(env)
        add_custom_relations(env) && next_actor.create(env)
      end
        
      def update(env)
        add_custom_relations(env) && next_actor.update(env)
      end

      private
        def add_custom_relations(env)
          attributes_collection = env.attributes.delete(:related_members_attributes)

          # before {"0"=>{"id"=>"6e9740ab-fc9c-403f-9e01-9c06c85148ee", "_destroy"=>"false"}, "1"=>{"id"=>"9abb566c-4873-4565-b02b-b32c7dd46fc8", "_destroy"=>"false"}}
          # after  [{"id"=>"6e9740ab-fc9c-403f-9e01-9c06c85148ee", "_destroy"=>"false"}, {"id"=>"9abb566c-4873-4565-b02b-b32c7dd46fc8", "_destroy"=>"false"}]
          attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
          
          # checking for existing works to avoid rewriting/loading works that are already attached
          existing_previous_works = env.curation_concern.previous_version
          attributes_collection.each do |attributes|
            next if attributes['id'].blank?
            if existing_previous_works&.include?(attributes['id'])
              remove(env.curation_concern, attributes['id']) if
                ActiveModel::Type::Boolean.new.cast(attributes['_destroy'])
            else
              add(env, attributes['id'])
            end
          end
          true
        end

        def add(env, id)
          work = Oer.find(id)
          env.curation_concern.previous_version << work
        end

        def remove(curation_concern, id)
          work = Oer.find(id)
          curation_concern.previous_version.delete(work)
        end

    end
  end
end
