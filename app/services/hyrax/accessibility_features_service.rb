module Hyrax
  module AccessibilityFeaturesService
    mattr_accessor :authority
    self.authority = Qa::Authorities::Local.subauthority_for('accessibility_features')

    def self.select_all_options
      authority.all.map do |element|
        [element[:label], element[:id]]
      end
    end

    def self.label(id)
      authority.find(id).fetch('term')
    end

    ##
    # @param [String, nil] id identifier of the resource type
    #
    # @return [String] a schema.org type. Gives the default type if `id` is nil.
    def self.microdata_type(id)
      return Hyrax.config.microdata_default_type if id.nil?
      Microdata.fetch("accessibility_feature_type.#{id}", default: Hyrax.config.microdata_default_type)
    end
  end
end
