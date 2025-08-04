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
      full_name = work_type.to_s                   # e.g. "GenericWorkResource"
      base_name = full_name.gsub(/Resource$/, '')  # e.g. "GenericWork"

      # 0) System-level models are always valid
      return if [Hyrax.config.admin_set_model,
                 Hyrax.config.collection_model,
                 Hyrax.config.file_set_model].map(&:to_s).include?(full_name)

      # 1) Profile validation (only when Flexible Metadata is active)
      if Hyrax.config.flexible?
        profile = Hyrax::FlexibleSchema.current_version
        if profile
          profile_classes    = profile.dig('classes')&.keys || []
          profile_work_types = profile_classes.map { |klass| klass.gsub(/Resource$/, '') }

          unless profile_work_types.include?(base_name)
            raise StandardError,
                  "Work type '#{full_name}' is not defined in the current metadata profile. " \
                  'Please add it to the profile.'
          end
        end
      end

      # 2) Tenant validation (must be listed in Site.available_works)
      unless Site.instance.available_works.include?(full_name) ||
             Site.instance.available_works.include?(base_name)
        raise StandardError,
              "Work type '#{full_name}' is not enabled for this tenant. " \
              "Please enable it via the 'Available Work Types' setting of the Admin Dashboard."
      end
    end
  end
end

::Bulkrax::ObjectFactoryInterface.prepend(Bulkrax::ObjectFactoryInterfaceDecorator)
