# frozen_string_literal: true

# OVERRIDES BULKRAX v9.1.0
#
# Validates the work type for a given entry at the beginning of the import
# process. This ensures that we don't attempt to process an entry for a work
# type that isn't enabled for the tenant or defined in the current metadata
# profile, which would otherwise result in a cryptic KeyError.
module Bulkrax
  module ImportBehaviorDecorator
    # Overriding the entire method to inject validation at the correct place.
    def build_for_importer
      begin
        # OVERRIDE begin
        validate_work_type!(factory_class)
        # OVERRIDE end

        build_metadata
        unless importerexporter.validate_only
          raise CollectionsCreatedError unless collections_created?
          @item = factory.run!
          add_user_to_permission_templates!
          parent_jobs if parsed_metadata[related_parents_parsed_mapping]&.join.present?
          child_jobs if parsed_metadata[related_children_parsed_mapping]&.join.present?
        end
      rescue RSolr::Error::Http, CollectionsCreatedError => e
        raise e
      rescue StandardError => e
        set_status_info(e)
      else
        set_status_info
      ensure
        save!
      end
      return @item
    end

    private

    # Ensure the supplied work type is defined in the flexible-schema profile
    # (when enabled) and allowed for the current tenant.
    #
    # @param work_type [Class] the Valkyrie/ActiveFedora work class
    # @raise [StandardError] when the work type is invalid for the profile or tenant
    def validate_work_type!(work_type)
      full_name = work_type.to_s
      base_name = full_name.gsub(/Resource$/, '')

      # System-level models like Collections and FileSets don't need validation.
      return if system_level_model?(full_name)

      validate_profile!(full_name, base_name) if flexible_metadata_enabled?
      validate_tenant!(full_name, base_name)
    end

    def system_level_model?(full_name)
      system_models = [
        Hyrax.config.admin_set_model,
        Hyrax.config.collection_model,
        Hyrax.config.file_set_model
      ].map(&:to_s)

      system_models.include?(full_name)
    end

    def flexible_metadata_enabled?
      defined?(Hyrax.config.flexible?) && Hyrax.config.flexible?
    end

    def validate_profile!(full_name, base_name)
      profile = Hyrax::FlexibleSchema.current_version
      return unless profile

      profile_work_types = extract_profile_work_types(profile)
      return if profile_work_types.include?(base_name)

      raise StandardError,
            "Work type '#{full_name}' is not defined in the current metadata profile. " \
            'Please add it to the profile.'
    end

    def extract_profile_work_types(profile)
      profile_classes = profile.dig('classes')&.keys || []
      profile_classes.map { |klass| klass.gsub(/Resource$/, '') }
    end

    def validate_tenant!(full_name, base_name)
      available_works = Site.instance.available_works
      return if available_works.include?(full_name) || available_works.include?(base_name)

      raise StandardError,
            "Work type '#{full_name}' is not enabled for this tenant. " \
            "Please enable it via the 'Available Work Types' setting of the Admin Dashboard."
    end
  end
end

Bulkrax::ImportBehavior.prepend(Bulkrax::ImportBehaviorDecorator)
