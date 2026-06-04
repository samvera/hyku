# frozen_string_literal: true

module Hyku
  # Overrides CarrierWave's storage path for site branding uploaders (banner, logo, favicon, etc.)
  # to use Hyrax.config.branding_path (a permanent, tenant-scoped directory) instead of the
  # default Paperclip-compat path (public/system) or the temporary upload staging path.
  #
  # Also provides a fallback for files that were previously stored at legacy locations, emitting
  # a deprecation warning so operators know to run the migration rake tasks.
  module BrandingStoreable
    # CarrierWave's Paperclip compat appends /{style}/{filename} to this, giving:
    #   {branding_base}/{tenant}/{model_class}/{attachment_plural}/{id}/original/{filename}
    def store_dir
      File.join(
        Hyrax.config.branding_path.to_s,
        Apartment::Tenant.current,
        model.class.name.underscore,
        mounted_as.to_s.pluralize
      )
    end

    def retrieve_from_store!(identifier)
      super
      return if file.try(:exists?)

      legacy_locations(identifier).each do |legacy_path|
        next unless File.exist?(legacy_path)

        Deprecation.warn(
          self,
          "Branding image '#{identifier}' was found at a legacy path (#{legacy_path}). " \
          "Run `rake hyku:branding:migrate:copy` to move it to the permanent branding directory. " \
          "This fallback will be removed in the next major release."
        )
        @file = CarrierWave::SanitizedFile.new(legacy_path)
        break
      end
    end

    private

    def legacy_locations(identifier)
      upload_base = Hyrax.config.upload_path.call.to_s
      class_dir   = model.class.name.underscore
      attach_dir  = mounted_as.to_s.pluralize
      id_dir      = model.id.to_s

      [
        # Old upload-path storage without style subdir
        File.join(upload_base, class_dir, attach_dir, id_dir, identifier),
        # Old upload-path storage with original style subdir
        File.join(upload_base, class_dir, attach_dir, id_dir, 'original', identifier),
        # Paperclip compat default before branding_path override (public/system)
        Rails.root.join('public', 'system', attach_dir, id_dir, 'original', identifier).to_s
      ]
    end
  end
end
