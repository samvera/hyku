require 'importer/log_subscriber'
module Importer
  module Factory
    class ObjectFactory
      extend ActiveModel::Callbacks
      define_model_callbacks :save, :create
      class_attribute :klass, :system_identifier_field
      attr_reader :attributes, :files_directory, :object, :files

      def initialize(attributes, files_dir = nil, files = [])
        @attributes = attributes
        @files_directory = files_dir
        @files = files
      end

      def run
        arg_hash = { id: attributes[:id], name: 'UPDATE', klass: klass }
        @object = find
        if @object
          ActiveSupport::Notifications.instrument('import.importer', arg_hash) { update }
        else
          ActiveSupport::Notifications.instrument('import.importer', arg_hash.merge(name: 'CREATE')) { create }
        end
        yield(object) if block_given?
        object
      end

      def update
        raise "Object doesn't exist" unless object
        run_callbacks(:save) do
          work_actor.update(environment(update_attributes))
        end
        log_updated(object)
      end

      def create_attributes
        { collection_type: collection_type }.merge(transform_attributes)
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

      def collection_type
        @collection_type ||= Hyrax::CollectionType.find_or_create_default_collection_type
      end

      # An ActiveFedora bug when there are many habtm <-> has_many associations means they won't all get saved.
      # https://github.com/projecthydra/active_fedora/issues/874
      # 2+ years later, still open!
      def create
        attrs = create_attributes
        @object = klass.new
        run_callbacks :save do
          run_callbacks :create do
            klass == Collection ? create_collection(attrs) : work_actor.create(environment(attrs))
          end
        end
        log_created(object)
      end

      def log_created(obj)
        msg = "Created #{klass.model_name.human} #{obj.id}"
        Rails.logger.info("#{msg} (#{Array(attributes[system_identifier_field]).first})")
      end

      def log_updated(obj)
        msg = "Updated #{klass.model_name.human} #{obj.id}"
        Rails.logger.info("#{msg} (#{Array(attributes[system_identifier_field]).first})")
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

        # NOTE: This approach is probably broken since the actor that handled `:files` attribute was removed:
        # https://github.com/samvera/hyrax/commit/3f1b58195d4381c51fde8b9149016c5b09f0c9b4
        def file_attributes
          files_directory.present? && files.present? ? { files: file_paths } : {}
        end

        def file_paths
          files.map { |file_name| File.join(files_directory, file_name) }
        end

        # Regardless of what the MODS Parser gives us, these are the properties we are prepared to accept.
        def permitted_attributes
          klass.properties.keys.map(&:to_sym) + %i[id edit_users edit_groups read_groups visibility]
        end
    end
  end
end
