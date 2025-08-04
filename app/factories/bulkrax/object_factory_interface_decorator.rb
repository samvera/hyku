# frozen_string_literal: true

# TODO: remove when issue https://github.com/notch8/hykuup_knapsack/issues/387 has been addressed and updated into this repo

module Bulkrax
  module ObjectFactoryInterfaceDecorator
    # Perform a work-type sanity check before the factory creates/updates the
    # object.  Any failure is rescued by Bulkrax and recorded on the Entry.
    def run(&block)
      validate_work_type!(klass)
      super(&block)
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
      Hyrax.config.flexible?
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

::Bulkrax::ObjectFactoryInterface.prepend(Bulkrax::ObjectFactoryInterfaceDecorator)
