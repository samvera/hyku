require 'importer/log_subscriber'
module Importer
  module Factory
    # rubocop:disable Metrics/ClassLength
    class ObjectFactory
      extend ActiveModel::Callbacks
      define_model_callbacks :save, :create

      class_attribute :klass, :system_identifier_field

      attr_reader :attributes, :files_directory, :object, :files

      def initialize(attributes, files_dir = nil, files = [])
        @files_directory = files_dir
        @files = files
        @attributes = attributes
      end

      # rubocop:disable Metrics/MethodLength
      def run
        # rubocop:disable Lint/AssignmentInCondition
        if @object = find
          ActiveSupport::Notifications.instrument('import.importer',
                                                  id: attributes[:id], name: 'UPDATE', klass: klass) do
            update
          end
        else
          ActiveSupport::Notifications.instrument('import.importer',
                                                  id: attributes[:id], name: 'CREATE', klass: klass) do
            create
          end
        end
        # rubocop:enable Lint/AssignmentInCondition

        yield(object) if block_given?
        object
      end
      # rubocop:enable Metrics/MethodLength

      def update
        raise "Object doesn't exist" unless object
        run_callbacks(:save) do
          work_actor.update(environment(update_attributes))
        end
        log_updated(object)
      end

      def create_attributes
        transform_attributes
      end

      def update_attributes
        transform_attributes.except(:id)
      end

      def find
        return find_by_id if attributes[:id]
        return search_by_identifier if attributes[system_identifier_field].present?
        raise "Missing identifier: Unable to search for existing object without " \
          "either fedora ID or #{system_identifier_field}"
      end

      def find_by_id
        klass.find(attributes[:id]) if klass.exists?(attributes[:id])
      end

      def search_by_identifier
        query = { Solrizer.solr_name(system_identifier_field, :symbol) =>
                    attributes[system_identifier_field] }
        klass.where(query).first
      end

      # rubocop:disable Metrics/MethodLength
      def create
        attrs = create_attributes

        # There's a bug in ActiveFedora when there are many
        # habtm <-> has_many associations, where they won't all get saved.
        # https://github.com/projecthydra/active_fedora/issues/874
        @object = klass.new
        run_callbacks :save do
          run_callbacks :create do
            if klass == Collection
              create_collection(attrs)
            else
              work_actor.create(environment(attrs))
            end
          end
        end

        log_created(object)
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      def log_created(obj)
        Rails.logger.info(
          "Created #{klass.model_name.human} #{obj.id} (#{Array(attributes[system_identifier_field]).first})"
        )
      end

      def log_updated(obj)
        Rails.logger.info(
          "Updated #{klass.model_name.human} #{obj.id} (#{Array(attributes[system_identifier_field]).first})"
        )
      end

      private

        # @param [Hash] attrs the attributes to put in the environment
        # @return [Hyrax::Actors::Environment]
        def environment(attrs)
          Hyrax::Actors::Environment.new(@object, Ability.new(User.batch_user), attrs)
        end

        def work_actor
          Hyrax::CurationConcern.actor
        end

        def create_collection(attrs)
          @object.attributes = attrs
          @object.apply_depositor_metadata(User.batch_user)
          @object.save!
        end

        # Override if we need to map the attributes from the parser in
        # a way that is compatible with how the factory needs them.
        def transform_attributes
          StringLiteralProcessor.process(attributes.slice(*permitted_attributes))
                                .merge(file_attributes)
        end

        # NOTE: This approach is probably broken since the actor that handled
        # the `:files` attribute no longer exists:
        # https://github.com/samvera/hyrax/commit/3f1b58195d4381c51fde8b9149016c5b09f0c9b4
        def file_attributes
          files_directory.present? && files.present? ? { files: file_paths } : {}
        end

        def file_paths
          files.map { |file_name| File.join(files_directory, file_name) }
        end

        # Regardless of what the MODS Parser gives us, these are the properties
        # we are prepared to accept.
        def permitted_attributes
          klass.properties.keys.map(&:to_sym) +
            [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
