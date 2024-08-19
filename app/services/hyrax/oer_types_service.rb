# frozen_string_literal: true
module Hyrax
  module OerTypesService
    mattr_accessor :authority
    self.authority = Qa::Authorities::Local.subauthority_for('oer_types')

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
      Microdata.fetch("type.#{id}", default: Hyrax.config.microdata_default_type)
    end
  end
end
