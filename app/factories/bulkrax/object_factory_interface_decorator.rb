# frozen_string_literal: true

# TODO: remove when issue https://github.com/notch8/hykuup_knapsack/issues/387 has been addressed and updated into this repo

# OVERRIDES BULKRAXv9.1.0 to validate work types against the profile and tenant

module Bulkrax
  module ObjectFactoryInterfaceDecorator
    # Perform a work-type sanity check before the factory creates/updates the
    # object.  Any failure is rescued by Bulkrax and recorded on the Entry.
    def run(&block)
      Rails.logger.info "🔍 VALIDATION: ObjectFactoryInterface#run called for #{klass}"
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
      Rails.logger.info "🔍 VALIDATION: validate_work_type! called for #{work_type}"
      full_name = work_type.to_s
      base_name = full_name.gsub(/Resource$/, '')

      return if system_level_model?(full_name)

      validate_profile!(full_name, base_name) if flexible_metadata_enabled?
      validate_tenant!(full_name, base_name)
      Rails.logger.info "🔍 VALIDATION: work type #{work_type} passed validation"
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
      Rails.logger.info "🔍 VALIDATION: validate_profile! called for #{full_name}/#{base_name}"
      profile = Hyrax::FlexibleSchema.current_version
      return unless profile

      profile_work_types = extract_profile_work_types(profile)
      return if profile_work_types.include?(base_name)

      error_msg = "Work type '#{full_name}' is not defined in the current metadata profile. Please add it to the profile."
      Rails.logger.error "🔍 VALIDATION ERROR: #{error_msg}"
      raise StandardError, error_msg
    end

    def extract_profile_work_types(profile)
      profile_classes = profile.dig('classes')&.keys || []
      profile_classes.map { |klass| klass.gsub(/Resource$/, '') }
    end

    def validate_tenant!(full_name, base_name)
      Rails.logger.info "🔍 VALIDATION: validate_tenant! called for #{full_name}/#{base_name}"
      available_works = Site.instance.available_works
      return if available_works.include?(full_name) || available_works.include?(base_name)

      error_msg = "Work type '#{full_name}' is not enabled for this tenant. Please enable it via the 'Available Work Types' setting of the Admin Dashboard."
      Rails.logger.error "🔍 VALIDATION ERROR: #{error_msg}"
      raise StandardError, error_msg
    end
  end

  # Decorator for ValkyrieObjectFactory to ensure validation runs for Valkyrie objects
  # since ValkyrieObjectFactory overrides create/update and bypasses the run method
  module ValkyrieObjectFactoryDecorator
    def create
      Rails.logger.info "🔍 VALIDATION: ValkyrieObjectFactory#create called for #{klass}"
      validate_work_type!(klass)
      super
    end

    def update
      Rails.logger.info "🔍 VALIDATION: ValkyrieObjectFactory#update called for #{klass}"
      validate_work_type!(klass)
      super
    end

    include ObjectFactoryInterfaceDecorator
  end
end

::Bulkrax::ObjectFactoryInterface.prepend(Bulkrax::ObjectFactoryInterfaceDecorator)
::Bulkrax::ValkyrieObjectFactory.prepend(Bulkrax::ValkyrieObjectFactoryDecorator)
