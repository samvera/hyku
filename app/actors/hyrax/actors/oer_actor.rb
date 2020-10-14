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
          attributes = attributes_collection&.sort_by { |i, _| i.to_i }&.map { |_, attributes| attributes }

          # checking for existing works to avoid rewriting/loading works that are already attached
          existing_previous_works = env.curation_concern.previous_version_id
          existing_newer_works = env.curation_concern.newer_version_id
          existing_alternate_works = env.curation_concern.alternate_version_id
          existing_related_items = env.curation_concern.related_item_id

          attributes&.each do |attributes|
            next if attributes['id'].blank?
            if existing_previous_works&.include?(attributes['id']) ||
               existing_newer_works&.include?(attributes['id']) ||
               existing_alternate_works&.include?(attributes['id']) ||
               existing_related_items&.include?(attributes['id'])

              if existing_previous_works&.include?(attributes['id'])
                env = remove(env, attributes['id'], attributes['relationship']) if
                  ActiveModel::Type::Boolean.new.cast(attributes['_destroy']) && attributes['relationship'] == 'previous-version'
              elsif existing_newer_works&.include?(attributes['id'])
                env = remove(env, attributes['id'], attributes['relationship']) if
                ActiveModel::Type::Boolean.new.cast(attributes['_destroy']) && attributes['relationship'] == 'newer-version'
              elsif existing_alternate_works&.include?(attributes['id'])
                env = remove(env, attributes['id'], attributes['relationship']) if
                ActiveModel::Type::Boolean.new.cast(attributes['_destroy']) && attributes['relationship'] == 'alternate-version'
              elsif existing_related_items&.include?(attributes['id'])
                env = remove(env, attributes['id'], attributes['relationship']) if
                ActiveModel::Type::Boolean.new.cast(attributes['_destroy']) && attributes['relationship'] == 'related-item'
              end
            else
              env = add(env, attributes['id'], attributes['relationship'])
            end
          end
          env
        end

        def add(env, id, relationship)
          rel = "#{relationship.underscore}_id"
          case rel
          when "previous_version_id"
            env.curation_concern.previous_version_id = (env.curation_concern.previous_version_id.to_a << id)
          when "newer_version_id"
            env.curation_concern.newer_version_id = (env.curation_concern.newer_version_id.to_a << id)
          when "alternate_version_id"
            env.curation_concern.alternate_version_id = (env.curation_concern.alternate_version_id.to_a << id)
          when "related_item_id"
            env.curation_concern.related_item_id = (env.curation_concern.related_item_id.to_a << id)
          end
          env.curation_concern.save
          env
        end

        def remove(env, id, relationship)
          rel = "#{relationship.underscore}_id"
          case rel
          when "previous_version_id"
            env.curation_concern.previous_version_id = (env.curation_concern.previous_version_id.to_a - [id])
          when "newer_version_id"
            env.curation_concern.newer_version_id = (env.curation_concern.newer_version_id.to_a - [id])
          when "alternate_version_id"
            env.curation_concern.alternate_version_id = (env.curation_concern.alternate_version_id.to_a - [id])
          when "related_item_id"
            env.curation_concern.related_item_id = (env.curation_concern.related_item_id.to_a - [id])
          end
          env.curation_concern.save
          env
        end
    end
  end
end
